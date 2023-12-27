require "open3"
require 'tmpdir'
require 'fileutils'
require 'pathname'

command = ARGV[2]
args = ARGV[3..]

Dir.mktmpdir(nil, '.') do |dir|
  work_dir = Pathname.new(File.join(dir, command))
  FileUtils.mkdir_p(work_dir)

  FileUtils.cp(command, work_dir)

  Dir.chroot(dir)

  stdout, stderr, status = Open3.capture3(command, *args)

  STDOUT.write(stdout)
  STDERR.write(stderr)

  exit(status.exitstatus)
end
