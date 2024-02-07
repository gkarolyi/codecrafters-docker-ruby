# frozen_string_literal: true

require_relative 'docker'

docker_cmd    = ARGV[0]
docker_tag    = ARGV[1]
command       = ARGV[2]
args          = ARGV[3..]

Docker.run(docker_tag, command, *args)
# binding.irb
