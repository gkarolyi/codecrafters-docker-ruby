require 'net/http'
require 'json'
require 'tmpdir'
require 'fileutils'
require 'fiddle'

require_relative 'docker/chroot'
require_relative 'docker/auth'

module Docker
  extend self

  def run(tag, command, *args, &block)
    Chroot.for(command) do
      pid = Process.spawn(command, *args)
      _, status = Process.wait2(pid)

      exit(status.exitstatus)
    end
  end
end
