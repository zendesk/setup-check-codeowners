#!/usr/bin/env ruby

require 'set'
require 'shellwords'
require 'tempfile'

require_relative './lib/check_codeowners'

cli = CheckCodeowners::CLI.new(root_path: Dir.pwd)
exit_status = cli.run
exit exit_status
