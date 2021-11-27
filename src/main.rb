#!/usr/bin/env ruby

require 'set'
require 'shellwords'
require 'tempfile'

require_relative 'lib/check_codeowners/multi_git_ls_runner'
require_relative 'lib/check_codeowners/entry'
require_relative 'lib/check_codeowners/codeowners'
require_relative 'lib/check_codeowners/codeowners_ignore'
require_relative 'lib/check_codeowners/individual_pattern_checker'
require_relative 'lib/check_codeowners/owner_entry'
require_relative 'lib/check_codeowners/get_options'
require_relative 'lib/check_codeowners/git_ls'
require_relative 'lib/check_codeowners/reports'
require_relative 'lib/check_codeowners/repository'
require_relative 'lib/check_codeowners/valid_owners'

def check_sorted(owner_entries)
  errors = []

  # We could auto-fix this, if it wasn't for comments and blank lines
  owner_entries.each_with_index.select do |entry, index|
    if index > 0 && entry.pattern <= owner_entries[index - 1].pattern
      errors << {
        code: "codeowners_file_not_in_sequence",
        message: "Line is duplicated or out of sequence at #{entry.file}:#{entry.line_number}",
        entry: entry
      }
    end
  end

  Struct.new(:errors).new(errors)
end

def check_indent(owner_entries)
  errors = []

  # We could auto-fix this
  owner_entries.each_with_index.select do |entry, index|
    if index > 0 && entry.indent != owner_entries[index - 1].indent
      errors << {
        code: "mismatched_indent",
        message: "Mismatched indent at #{entry.file}:#{entry.line_number}",
        entry: entry
      }
    end
  end

  Struct.new(:errors).new(errors)
end

def check_valid_owners(repo, owner_entries)
  # This is just to catch typos.
  # We could look up against github, of course.
  # For now, hard-wired is better than nothing.
  valid_owners = repo.valid_owners.valid_owners

  errors = []

  if valid_owners
    owner_entries.each do |entry|
      bad_owners = entry.owners - valid_owners

      bad_owners.each do |bad_owner|
        errors << {
          code: "invalid_owner",
          message: "Invalid owner #{bad_owner} at #{entry.file}:#{entry.line_number}",
          bad_owner: bad_owner,
          entry: entry
        }
      end
    end
  end

  Struct.new(:errors).new(errors)
end

# Warns if there are entries in the ignore file that are now owned
# Errors if there are files that don't have an owner (except if the file is included in ignore)
def check_unowned_files(repo, unowned_files, options)
  unowned_files = Set.new(unowned_files)
  ignore_file = repo.codeowners_ignore

  warnings = []
  errors = []
  used_ignores = Set.new
  ignored_unowned = Set.new

  if options.should_check_sorted
    errors.concat(ignore_file.check_sorted)
  end

  unowned_files.each do |unowned_file|
    if ignore_file.files.include?(unowned_file)
      ignored_unowned.add(unowned_file)
      used_ignores.add(unowned_file)
    end

    ignore_file.patterns.each do |ignore_pattern|
      if File.fnmatch?(ignore_pattern, unowned_file)
        ignored_unowned.add(unowned_file)
        used_ignores.add(ignore_pattern)
      end
    end
  end

  non_ignored_files = unowned_files - ignored_unowned
  non_ignored_files.sort.each do |file|
    errors << {
      code: "non_ignored_files",
      message: "Please add this file to #{repo.codeowners.path}: #{file}", # This file does not have an owner
      unowned: file,
    }
  end

  unused_ignores = (ignore_file.files + ignore_file.patterns) - used_ignores.to_a
  unused_ignores.sort.each do |unused_ignore|
    warnings << {
      code: "unused_ignore",
      message: "The following entry in #{ignore_file.path} doesn't match any unowned files and should be removed: #{unused_ignore}", # Obsolete entry
      unused_ignore: unused_ignore,
    }
  end

  Struct.new(:warnings, :errors).new(warnings, errors)
end

def run_all_checks(repo, codeowners, owner_entries, options)
  warnings = []
  errors = []

  errors.concat(codeowners.errors)

  if options.should_check_sorted
    r = check_sorted(owner_entries)
    errors.concat(r.errors)
  end

  if options.should_check_indent
    r = check_indent(owner_entries)
    errors.concat(r.errors)
  end

  if options.should_check_valid_owners
    r = check_valid_owners(repo, owner_entries)
    errors.concat(r.errors)
  end

  all_files = repo.git_ls.all_files

  if options.check_unowned
    all_files = repo.git_ls.all_files.to_set
    owned_files = repo.git_ls.matching_files(owner_entries.map(&:pattern)).to_set
    unowned = (all_files - owned_files).sort
    r = check_unowned_files(repo, unowned, options)
    warnings.concat(r.warnings)
    errors.concat(r.errors)
  end

  match_map = if options.find_redundant_ignores
                warnings.concat(repo.individual_pattern_checker.warnings)
                repo.individual_pattern_checker.match_map
              end

  Struct.new(:errors, :warnings, :all_files, :match_map).new(errors, warnings, all_files, match_map)
end

def show_checks_json(entries, owner_entries, r, options)
  output = {
    errors: r.errors,
    warnings: r.warnings
  }

  if options.debug
    output.merge!(
      entries: entries,
      owner_entries: owner_entries,
      all_files: r.all_files,
      match_map: r.match_map,
    )
  end

  require 'json'
  puts JSON.pretty_generate(output)
end

def show_checks_text(r)
  r.errors.each { |item| puts "ERROR: #{item[:message]}" }
  r.warnings.each { |item| puts "WARNING: #{item[:message]}" }

  if r.errors.any? || r.warnings.any?
    puts "For help, see https://github.com/zendesk/setup-check-codeowners/blob/main/Usage.md"
  end
end

# MAIN START

options = GetOptions.new(ARGV)

repo = Repository.new

owner_entries = repo.codeowners.owner_entries

if options.who_owns
  Reports.new(repo, options).who_owns
  exit
end

if options.files_owned
  Reports.new(repo, options).files_owned
  exit
end

# CHECK MODE

r = run_all_checks(repo, repo.codeowners, owner_entries, options)

if options.strict
  r.errors.concat(r.warnings)
  r.warnings = []
end

if options.show_json
  show_checks_json(repo.codeowners.entries, owner_entries, r, options)
else
  show_checks_text(r)
end

exit 1 if r.errors.any?
exit 0
