#!/usr/bin/env ruby

require 'set'
require 'shellwords'
require 'tempfile'

require_relative './lib/check_codeowners'

options = CheckCodeowners::GetOptions.new(ARGV)

repo = CheckCodeowners::Repository::Repository.new

if options.who_owns
  CheckCodeowners::Reports.new(repo, options).who_owns
  exit
end

if options.files_owned
  CheckCodeowners::Reports.new(repo, options).files_owned
  exit
end

checker = CheckCodeowners::CheckRunner.new(repo, options)
checker.show_checks
exit 1 if checker.errors?
exit 0
