module Docker
  class Chroot
    attr_reader :command, :dir

    CLONE_NEWPID = 0x20000000
    UNSHARE = Fiddle::Function.new(
      Fiddle::Handle::DEFAULT['unshare'],
      [Fiddle::TYPE_INT],
      Fiddle::TYPE_INT
    )

    def self.for(command, &block)
      begin
        chroot = new(command)
        chroot.create!
        yield
      ensure
        FileUtils.rm_rf(chroot.dir)
      end
    end

    def initialize(command)
      @command = command
      @dir = Dir.mktmpdir
    end

    def create!
      FileUtils.mkdir_p(work_dir)
      FileUtils.mkdir_p(proc_dir)

      FileUtils.cp(command, work_dir)
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
