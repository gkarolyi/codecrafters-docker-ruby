require 'net/http'
require 'json'

module Docker
  class Auth
    ARCHITECTURE = 'arm64'
    OS = 'linux'

    attr_reader :image, :version

    def initialize(docker_tag)
      @image = docker_tag.split(':').first
      @version = docker_tag.split(':').last
    end

    def token
      @token ||= Net::HTTP.start('auth.docker.io', 443, use_ssl: true) do |http|
        request = Net::HTTP::Get.new("/token?service=registry.docker.io&scope=repository:library/#{image}:pull")
        response = http.request(request)

        if response.code == '200'
          return JSON.parse(response.body)['token']
        else
          puts "Error: Failed to authenticate with Docker Hub"
          exit 1
        end
      end
    end

    def manifest
      @manifest ||= Net::HTTP.start('registry.hub.docker.com', 443, use_ssl: true) do |http|
        request = Net::HTTP::Get.new("/v2/library/#{image}/manifests/#{version}")
        request['Authorization'] = "Bearer #{token}"
        request['Accept'] = "application/vnd.docker.distribution.manifest.v2+json"
        response = http.request(request)

        if response.code == '200'
          return JSON.parse(response.body)['manifests']
        else
          puts "Error: Failed to fetch manifest from Docker Hub"
          exit 1
        end
      end
    end

    def layers
      @layers ||= manifest.select do |layer|
        layer['platform']['architecture'] == ARCHITECTURE &&
        layer['platform']['os'] == OS
      end
    end

    def pull_layers!
      layers.each do |layer|
        digest = layer['digest']
        p "digest: #{digest}"
        Net::HTTP.start('registry.hub.docker.com', 443, use_ssl: true) do |http|
          request = Net::HTTP::Get.new("/v2/library/#{image}/blobs/#{digest}")
          request['Authorization'] = "Bearer #{token}"
          # request['Accept'] = "application/vnd.docker.distribution.manifest.v2+json"
          binding.irb
          response = http.request(request)
          return JSON.parse(response.body)

          if response.code == '200'
            return JSON.parse(response.body)
          else
            puts "Error: Failed to fetch layer from Docker Hub"
            exit 1
          end
        end
      end
    end

    def request(hostname:, path:, token: nil)
      Net::HTTP.start(hostname, 443, use_ssl: true) do |http|
        request = Net::HTTP::Get.new(path)
        request['Authorization'] = "Bearer #{token}" if token
        # request['Accept'] = "application/vnd.docker.distribution.manifest.v2+json"
        response = http.request(request)

        return JSON.parse(response.body)
      end
    end
  end
end
