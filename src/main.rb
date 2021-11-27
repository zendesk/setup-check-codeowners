#!/usr/bin/env ruby

require 'set'
require 'shellwords'
require 'tempfile'

require_relative 'lib/check_codeowners/multi_git_ls_runner'
require_relative 'lib/check_codeowners/entry'
require_relative 'lib/check_codeowners/codeowners'
require_relative 'lib/check_codeowners/codeowners_ignore'
require_relative 'lib/check_codeowners/owner_entry'
require_relative 'lib/check_codeowners/get_options'
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

def git_ls_files(args:)
  output = `git ls-files -z #{Shellwords.shelljoin(args)}`
  $?.success? or raise "git ls-files #{args.inspect} failed"

  output.split("\0")
end

def get_all_files
  git_ls_files(args: [])
end

def find_unowned_files(owner_entries, all_files)
  unowned_files = Set.new(all_files)

  Tempfile.open do |tmpfile|
    owner_entries.each do |entry|
      tmpfile.puts entry.pattern
    end

    tmpfile.flush

    owned_files = git_ls_files(args: ["--cached", "--ignored", "--exclude-from", tmpfile.path])
    unowned_files -= owned_files
  end

  # Report on any file which is not matched by any entry (unowned)
  unowned_files.sort
end

def check_individual_patterns(owner_entries)
  # Slow but thorough: use git to check which files each individual pattern matches
  # May not scale well!

  match_map = {}
  warnings = []

  matched_files_collection = MultiGitLsRunner.new(owner_entries.map { |e| e.pattern }).run

  owner_entries.each do |entry|
    matched_files = matched_files_collection[entry.pattern]

    # Report on any pattern which doesn't match any files (cruft)
    if matched_files.empty?
      warnings << {
        code: "unmatched_pattern",
        message: "Pattern #{entry.pattern} at #{entry.file}:#{entry.line_number} doesn't match any files",
        entry: entry,
      }
    end

    matched_files.each do |file|
      (match_map[file] ||= []) << entry
    end
  end

  # Should we report on any file matched by more than one entry?
  # It could indicate an unintended conflict. But what if the
  # "conflict" is absolutely intended? Maybe it's not worth checking.
  # Maybe "too many" owners is better than too few.

  Struct.new(:match_map, :warnings).new(match_map, warnings)
end

def report_file_ownership(results, show_json, json_root_key)
  if show_json
    require 'json'
    puts JSON.pretty_generate(json_root_key => results)
  else
    results.each do |result|
      if result[:owners].any?
        puts "#{result[:file]}\t#{result[:owners].join(' ')}"
      else
        puts "#{result[:file]}\t-"
      end
    end
  end
end

def report_who_owns(owner_entries, show_json, files)
  # Discards warnings
  match_map = check_individual_patterns(owner_entries).match_map

  results = files.map do |file|
    file = file.sub(/^\.\/+/, '')
    matches = match_map[file]
    owners = if matches
      matches.map(&:owners).flatten.sort.uniq
    end
    { file: file, owners: owners || [] }
  end

  report_file_ownership(results, show_json, :who_owns)
end

def report_files_owned(owner_entries, show_json, args)
  # We don't *have* to brute force every pattern - we could instead
  # run git ls-files per owner, not per pattern. But we already have
  # the code, so it's convenient.
  match_map = if args.any?
    # Discards warnings
    check_individual_patterns(owner_entries).match_map
  else
    {}
  end

  results = get_all_files.map do |file|
    matches = match_map[file]
    next unless matches

    owners = matches.map(&:owners).flatten.sort.uniq & args
    next unless owners.any?

    { file: file, owners: owners }
  end.compact

  report_file_ownership(results, show_json, :files_owned)
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

  all_files = get_all_files

  if options.check_unowned
    unowned = find_unowned_files(owner_entries, all_files)
    r = check_unowned_files(repo, unowned, options)
    warnings.concat(r.warnings)
    errors.concat(r.errors)
  end

  match_map = if options.find_redundant_ignores
                r = check_individual_patterns(owner_entries)
                warnings.concat(r.warnings)
                r.match_map
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
  files = (options.args.empty? ? get_all_files : options.args)
  report_who_owns(owner_entries, options.show_json, files)
  exit
end

if options.files_owned
  report_files_owned(owner_entries, options.show_json, options.args)
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
