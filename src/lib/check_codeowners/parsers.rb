class Parsers
  def parse_codeowners_file(path)
    lines = begin
              IO.readlines(path).map(&:chomp)
            rescue Errno::ENOENT
              []
            end

    owner_re = /\S+/

    errors = []

    entries = lines.each_with_index.map do |line, index|
      base = { line_number: index + 1, text: line, file: path }

      case line
      when "", /^#/
        # Could be used in the future to reconstruct the file
        Entry.new(base)
      when /^((\S+)\s+)(#{owner_re}( #{owner_re})*)$/
        base.merge!(pattern: $2, indent: ($1).length, owners: $3.split(' '))
        OwnerEntry.new(base)
      else
        Entry.new(base).tap do |entry|
          errors << {
            code: "unrecognised_line",
            message: "Unrecognised line at #{entry.file}:#{entry.line_number}",
            entry: entry
          }
        end
      end
    end

    Struct.new(:entries, :errors).new(entries, errors)
  end

  def parse_ignore_file(path, options)
    lines = begin
              IO.readlines(path).map(&:chomp)
            rescue Errno::ENOENT
              []
            end

    patterns = Set.new
    files = Set.new
    previous_line = nil

    errors = []

    lines.each_with_index do |line, index|
      next if line.empty? || line.start_with?("#")

      if previous_line && line <= previous_line && options.should_check_sorted
        errors << {
          message: "Line is duplicated or out of sequence at #{path}:#{index + 1}",
          code: "ignore_file_not_in_sequence",
          file: path,
          line: index + 1,
        }
      end

      previous_line = line

      if line.include?("*")
        patterns << line
      else
        files << line
      end
    end

    Struct.new(:patterns, :files, :errors).new(patterns, files, errors)
  end

  def parse_validowners(path)
    begin
      IO.readlines(path).map(&:chomp)
    rescue Errno::ENOENT
      nil
    end
  end
end
