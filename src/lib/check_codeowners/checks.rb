class Checks
  def initialize(repo, options)
    @repo = repo
    @options = options
  end

  def results
    @results ||= run_all_checks
  end

  private

  attr_reader :repo, :options

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

  def check_valid_owners(owner_entries)
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
  def check_unowned_files(unowned_files)
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

  def run_all_checks
    warnings = []
    errors = []

    owner_entries = repo.codeowners.owner_entries
    errors.concat(repo.codeowners.errors)

    if options.should_check_sorted
      r = check_sorted(owner_entries)
      errors.concat(r.errors)
    end

    if options.should_check_indent
      r = check_indent(owner_entries)
      errors.concat(r.errors)
    end

    if options.should_check_valid_owners
      r = check_valid_owners(owner_entries)
      errors.concat(r.errors)
    end

    all_files = repo.git_ls.all_files

    if options.check_unowned
      all_files = repo.git_ls.all_files.to_set
      owned_files = repo.git_ls.matching_files(owner_entries.map(&:pattern)).to_set
      unowned = (all_files - owned_files).sort
      r = check_unowned_files(unowned)
      warnings.concat(r.warnings)
      errors.concat(r.errors)
    end

    match_map = if options.find_redundant_ignores
                  warnings.concat(repo.individual_pattern_checker.warnings)
                  repo.individual_pattern_checker.match_map
                end

    Struct.new(:errors, :warnings, :all_files, :match_map).new(errors, warnings, all_files, match_map)
  end
end
