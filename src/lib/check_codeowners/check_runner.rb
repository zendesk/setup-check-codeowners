class CheckRunner
  def initialize(repo, options)
    @repo = repo
    @options = options
  end

  def show_checks
    r = Checks.new(repo, options).results

    if options.strict
      r.errors.concat(r.warnings)
      r.warnings = []
    end

    if options.show_json
      show_checks_json(r)
    else
      show_checks_text(r)
    end

    @has_errors = r.errors.any?
  end

  def errors?
    @has_errors
  end

  private

  attr_reader :repo, :options

  def show_checks_json(r)
    output = {
      errors: r.errors,
      warnings: r.warnings
    }

    if options.debug
      output.merge!(
        entries: report.codeowners.entries,
        owner_entries: report.codeowners.owner_entries,
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
end
