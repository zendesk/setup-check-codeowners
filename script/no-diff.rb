#!/usr/bin/env ruby

require 'fileutils'
FileUtils.rm_rf "bin"
Dir.mkdir "bin"

system "ruby ./script/build.rb"
$?.success? or exit 1

output = `git ls-files --modified --deleted bin`
$?.success? or exit 1

if output == ""
  exit 0
else
  system "git diff bin"
  exit 1
end
