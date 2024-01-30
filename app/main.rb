# frozen_string_literal: true

require_relative 'docker'

docker_cmd    = ARGV[0]
docker_tag    = ARGV[1]
command       = ARGV[2]
args          = ARGV[3..]

auth = Docker::Auth.new(docker_tag)
p auth.pull_layers!

Docker.run(docker_tag, command, *args)
# binding.irb
