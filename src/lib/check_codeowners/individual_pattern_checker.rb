module CheckCodeowners
  class IndividualPatternChecker
    # Given some owner_entries (i.e. a pattern and some owners),
    # *for each one individually* work out which actual files (as reported
    # by `git ls-files`) match that codeowners pattern.

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
      fast_matches, slow_patterns = find_fast_matches(owner_entries.map(&:pattern))
      slow_matches = find_slow_matches(slow_patterns)
      collate(fast_matches.merge(slow_matches))
    end

    def find_fast_matches(patterns)
      # Fast match (not using git to do the matching) "simple" patterns:
      #   /foo/bar (where that file exists) => matches exactly that file
      #   /foo/bar/ (where at least one file has that prefix) => matches those files

      # Everything else is collected into "slow_patterns", for matching via `git`

      all_files = Repository::GitLs.new.all_files # Haven't we already got this data?
      fast_matches_collection = {}
      slow_patterns = []

      patterns.each do |pattern|
        if pattern.match?(/\A(\/[^?*\[]+)*\/\z/)
          pattern_without_slash = pattern[1..-1]
          prefix_matches = all_files.select { |path| path.start_with?(pattern_without_slash) }
          if prefix_matches.any?
            fast_matches_collection[pattern] = prefix_matches
            next
          end
        end

        if pattern.match?(/\A(\/[^?*\[]+)+\z/)
          pattern_without_slash = pattern[1..-1]
          if all_files.include?(pattern_without_slash)
            fast_matches_collection[pattern] = [pattern_without_slash]
            next
          end
        end

        slow_patterns << pattern
      end

      [fast_matches_collection, slow_patterns]
    end

    def find_slow_matches(patterns)
      # According to https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners ,
      # CODEOWNERS patterns are _quite like_ (but not the same as) the
      # patterns used by "gitignore", so we're going to use git itself to
      # do all the pattern matching (in "MultiGitLsRunner").

      # However, one of the (undocumented) ways in which CODEOWNERS patterns
      # are *not* the same as gitignore patterns is if the pattern ends
      # in `/*`: for gitignore, that `*` matches both files and
      # subdirectories; whereas for CODEOWNERS, the `*` only matches files.

      # To deal with this, every time we see a `/*` pattern, we also ask git
      # to pattern match any subtrees, which we then remove from the match
      # list. So for example if the CODEOWNERS pattern is `/lib/*`, then
      # we'll ask git to provide the match results for `/lib/*` and also
      # `/lib/*/**`.

      # Which gitignore patterns we need match results for: all the
      # CODEOWNERS patterns, plus the `/* -> /*/**` additions.
      patterns += patterns.select { |patt| patt.end_with?("/*") }.map { |p| "#{p}/**" }

      MultiGitLsRunner.new(patterns).run
    end

    def collate(matched_files_collection)
      match_map = {}
      warnings = []

      owner_entries.each do |entry|
        matched_files = matched_files_collection[entry.pattern]

        # Apply the `/*/**` subtree removal hack
        if entry.pattern.end_with?('/*')
          matched_files -= matched_files_collection["#{entry.pattern}/**"]
        end

        # Report on any pattern which doesn't match any files (cruft)
        if matched_files.empty?
          warnings << {
            code: "unmatched_pattern",
            message: "Pattern #{entry.pattern} at #{entry.file}:#{entry.line_number} doesn't match any files",
            entry: entry,
          }
        end

        # For each file matching this CODEOWNERS pattern, update the
        # match_map. We process the owner entries in order, so it's
        # possible that a later pattern matches the same file and
        # overwrites; this implements the "latest wins" logic of
        # CODEOWNERS.
        matched_files.each do |file|
          match_map[file] = entry
        end
      end

      # Should we report on any file matched by more than one entry?
      # It could indicate an unintended conflict. But what if the
      # "conflict" is absolutely intended? Maybe it's not worth checking.
      # Maybe "too many" owners is better than too few.

      Struct.new(:match_map, :warnings).new(match_map, warnings)
    end
  end
end
