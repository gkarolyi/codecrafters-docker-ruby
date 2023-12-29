# frozen_string_literal: true

require 'open3'
require 'tmpdir'
require 'fileutils'

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

  stdout, stderr, status = Open3.capture3(command, *args)

  $stdout.write(stdout)
  $stderr.write(stderr)
ensure
  FileUtils.rm_rf(dir)
  exit(status.exitstatus)
end
