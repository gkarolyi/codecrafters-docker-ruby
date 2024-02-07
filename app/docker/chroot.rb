require 'tmpdir'
require 'fileutils'
require 'fiddle'

require_relative 'auth'

module Docker
  class Chroot
    attr_reader :command, :dir, :auth

    def self.for(docker_tag, command, &block)
      begin
        chroot = new(docker_tag, command)
        chroot.extract_layers!
        chroot.create_jail!
        chroot.create_pid_namespace!
        yield
      ensure
        FileUtils.rm_rf(chroot.dir)
      end
    end

    def initialize(docker_tag, command)
      @command = command
      @auth = Auth.new(docker_tag)
      @dir = Dir.mktmpdir
    end

    def extract_layers!
      Dir.mktmpdir do |tmp_dir|
        auth.pull_layers(folder: tmp_dir)
        system("tar xf #{tmp_dir}/* -C #{dir}")
      end
    end

    def create_jail!
      FileUtils.mkdir_p(work_dir)
      FileUtils.mkdir_p(proc_dir)

      begin
        FileUtils.cp(command, work_dir)
      rescue ArgumentError
      end

      system("mount -t proc none #{proc_dir}")
      Dir.chdir(dir)
      Dir.chroot(dir)
    end

    def create_pid_namespace!
      new_pid = unshare.call(0x20000000)

      if new_pid != 0
        puts "Error: Failed to create new PID namespace"
        exit 1
      end
    end

    private

    def unshare
      @unshare ||= Fiddle::Function.new(
        Fiddle::Handle::DEFAULT['unshare'],
        [Fiddle::TYPE_INT],
        Fiddle::TYPE_INT
      )
    end

    def work_dir
      @work_dir ||= File.join(dir, File.dirname(command))
    end

    def proc_dir
      @proc_dir ||= File.join(dir, 'proc')
    end
  end
end
