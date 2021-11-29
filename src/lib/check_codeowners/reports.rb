module CheckCodeowners
  class Reports
    def initialize(repo, options)
      @repo = repo
      @options = options
    end

    attr_reader :repo, :options

    def who_owns
      files = (options.args.empty? ? repo.git_ls.all_files : options.args)

      # Discards warnings
      match_map = repo.individual_pattern_checker.match_map

      results = files.map do |file|
        file = file.sub(/^\.\/+/, '')
        match = match_map[file]
        owners = if match
                   match.owners.sort.uniq
                 end
        { file: file, owners: owners || [] }
      end

      report_file_ownership(results, :who_owns)
    end

    def files_owned
      results = repo.git_ls.all_files.map do |file|
        # We don't *have* to brute force every pattern - we could instead
        # run git ls-files per owner, not per pattern. But we already have
        # the code, so it's convenient.
        # Discards warnings
        match = repo.individual_pattern_checker.match_map[file]
        next unless match

        owners = match.owners.sort.uniq & options.args
        next unless owners.any?

        { file: file, owners: owners }
      end.compact

      report_file_ownership(results, :files_owned)
    end

    private

    def report_file_ownership(results, json_root_key)
      if options.show_json
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
  end
end
