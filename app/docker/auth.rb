require 'net/http'
require 'json'

module Docker
  class Auth
    ARCHITECTURE = 'arm64'
    OS = 'linux'

    attr_reader :image, :version

    def initialize(docker_tag)
      @image, @version = docker_tag.split(':')
      @version ||= 'latest'
    end

    def pull_layers(folder:)
      layers.each do |layer|
        digest = layer['digest']
        response = pull_layer(digest: digest)
        file_blob = digest.split(':').last[..5]

        File.open("#{folder}/#{image}-layer-#{file_blob}", 'w') do |file|
          file.write(response)
        end
      end
    end

    private

    def token
      response = request(
        hostname: 'auth.docker.io',
        path: "/token?service=registry.docker.io&scope=repository:library/#{image}:pull"
      )
      return response.to_hash unless response.code == '200'

      JSON.parse(response.body)['token']
    end

    def manifest
      response = request(
        hostname: 'registry.hub.docker.com',
        path: "/v2/library/#{image}/manifests/#{version}",
        headers: {
          Authorization: "Bearer #{token}",
          Accept: "application/vnd.docker.distribution.manifest.v2+json"
        }
      )
      return response.to_hash unless response.code == '200'

      JSON.parse(response.body)
    end

    def layers
      if manifest['manifests']
        manifest['manifests'].select do |layer|
          layer['platform']['architecture'] == ARCHITECTURE &&
          layer['platform']['os'] == OS
        end
      else
        manifest['layers']
      end
    end


    def pull_layer(digest:)
      response = request(
        hostname: 'registry.hub.docker.com',
        path: "/v2/library/#{image}/blobs/#{digest}",
        headers: {
          Authorization: "Bearer #{token}"
        }
      )
      return response.body unless response.code == '307'

      uri = URI(response.to_hash['location'].first)
      Net::HTTP.get(uri)
    end

    def request(hostname:, path:, headers: nil)
      Net::HTTP.start(hostname, 443, use_ssl: true) do |http|
        request = Net::HTTP::Get.new(path)

        if headers
          request['Authorization'] = headers[:Authorization]
          request['Accept'] = headers[:Accept]
        end

        http.request(request)
      end
    end
  end
end
