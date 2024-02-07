require 'tmpdir'
require 'fileutils'
require 'fiddle'

require_relative 'auth'

module Docker
  class Chroot
    attr_reader :command, :dir, :tag

    CLONE_NEWPID = 0x20000000
    UNSHARE = Fiddle::Function.new(
      Fiddle::Handle::DEFAULT['unshare'],
      [Fiddle::TYPE_INT],
      Fiddle::TYPE_INT
    )

    def self.for(tag, command, &block)
      begin
        chroot = new(tag, command)
        chroot.extract_layers!
        chroot.create!
        yield
      ensure
        FileUtils.rm_rf(chroot.dir)
      end
    end

    def initialize(tag, command)
      @command = command
      @tag = tag
      @dir = Dir.mktmpdir
    end

    def extract_layers!
      Dir.mktmpdir do |tmp_dir|
        auth = Auth.new('alpine:latest')
        auth.pull_layers(folder: tmp_dir)
        system("tar xf #{tmp_dir}/* -C #{dir}")
      end
    end

    def create!
      FileUtils.mkdir_p(work_dir)
      FileUtils.mkdir_p(proc_dir)

      begin
        FileUtils.cp(command, work_dir)
      rescue ArgumentError
      end

      system("mount -t proc none #{proc_dir}")
      Dir.chdir(dir)
      Dir.chroot(dir)

      new_pid = UNSHARE.call(CLONE_NEWPID)

      if new_pid != 0
        puts "Error: Failed to create new PID namespace"
        exit 1
      end
    end

    def work_dir
      @work_dir ||= File.join(dir, File.dirname(command))
    end

    def proc_dir
      @proc_dir ||= File.join(dir, 'proc')
    end
  end
end
