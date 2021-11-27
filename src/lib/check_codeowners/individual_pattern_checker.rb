class IndividualPatternChecker
  def initialize(owner_entries)
    @owner_entries = owner_entries
  end

  def match_map
    results.match_map
  end

  def warnings
    results.warnings
  end

  private

  attr_reader :owner_entries

  def results
    @results ||= check_individual_patterns
  end

  def check_individual_patterns
    # Slow but thorough: use git to check which files each individual pattern matches
    # May not scale well!

    match_map = {}
    warnings = []

    matched_files_collection = MultiGitLsRunner.new(owner_entries.map(&:pattern)).run

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
end
