module CheckCodeowners
  class CheckRunner
    def initialize(repo, options)
      @repo = repo
      @options = options
    end

    def show_checks
      check_results = Checks.new(repo, options).results

      if options.strict
        check_results.errors.concat(check_results.warnings)
        check_results.warnings = []
      end

      if options.show_json
        show_checks_json(check_results)
      else
        show_checks_text(check_results)
      end

      @has_errors = check_results.errors.any?
    end

    def errors?
      @has_errors
    end

    private

    attr_reader :repo, :options

    def show_checks_json(check_results)
      output = {
        errors: check_results.errors,
        warnings: check_results.warnings
      }

      if options.debug
        output.merge!(
          entries: report.codeowners.entries,
          owner_entries: report.codeowners.owner_entries,
          all_files: check_results.all_files,
          match_map: check_results.match_map,
        )
      end

      require 'json'
      puts JSON.pretty_generate(output)
    end

    def show_checks_text(check_results)
      check_results.errors.each { |item| puts "ERROR: #{item[:message]}" }
      check_results.warnings.each { |item| puts "WARNING: #{item[:message]}" }

      if check_results.errors.any? || check_results.warnings.any?
        puts "For help, see https://github.com/zendesk/setup-check-codeowners/blob/main/Usage.md"
      end
    end
  end
end
