# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'fiddle'

CLONE_NEWPID = 0x20000000
unshare = Fiddle::Function.new(
  Fiddle::Handle::DEFAULT['unshare'],
  [Fiddle::TYPE_INT],
  Fiddle::TYPE_INT
)

command = ARGV[2]
args = ARGV[3..]
work_dir_name = File.dirname(command)


begin
  dir = Dir.mktmpdir

  work_dir = File.join(dir, work_dir_name)
  proc_dir = File.join(dir, 'proc')

  FileUtils.mkdir_p(work_dir)
  FileUtils.mkdir_p(proc_dir)

  FileUtils.cp(command, work_dir)
  system("mount -t proc none #{proc_dir}")

  Dir.chdir(dir)
  Dir.chroot(dir)


  new_pid = unshare.call(CLONE_NEWPID)

  if new_pid != 0
    puts "Error: Failed to create new PID namespace"
    exit 1
  end

  pid = Process.spawn(command, *args)
  _, status = Process.wait2(pid)

ensure
  FileUtils.rm_rf(dir)
end

exit(status.exitstatus)
