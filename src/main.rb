#!/usr/bin/env ruby

require 'set'
require 'shellwords'
require 'tempfile'

require_relative 'lib/check_codeowners/check_runner'
require_relative 'lib/check_codeowners/checks'
require_relative 'lib/check_codeowners/codeowners'
require_relative 'lib/check_codeowners/codeowners_ignore'
require_relative 'lib/check_codeowners/entry'
require_relative 'lib/check_codeowners/get_options'
require_relative 'lib/check_codeowners/git_ls'
require_relative 'lib/check_codeowners/individual_pattern_checker'
require_relative 'lib/check_codeowners/multi_git_ls_runner'
require_relative 'lib/check_codeowners/owner_entry'
require_relative 'lib/check_codeowners/reports'
require_relative 'lib/check_codeowners/repository'
require_relative 'lib/check_codeowners/valid_owners'

options = GetOptions.new(ARGV)

repo = Repository.new


if options.who_owns
  Reports.new(repo, options).who_owns
  exit
end

if options.files_owned
  Reports.new(repo, options).files_owned
  exit
end

# CHECK MODE

checker = CheckRunner.new(repo, options)
checker.show_checks
exit 1 if checker.errors?
exit 0
