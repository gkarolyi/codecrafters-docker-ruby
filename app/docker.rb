require_relative 'docker/chroot'

module Docker
  extend self

  def run(docker_tag, command, *args, &block)
    Chroot.for(docker_tag, command) do
      pid = Process.spawn(command, *args)
      _, status = Process.wait2(pid)

      exit(status.exitstatus)
    end
  end
end
