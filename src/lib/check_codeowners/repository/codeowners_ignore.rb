module CheckCodeowners
  module Repository
    class CodeownersIgnore
      Entry = Struct.new(:text, :filename, :line_number, keyword_init: true)

      def initialize(path, root_path:)
        @path = path
        @root_path = root_path
      end

      attr_reader :path, :root_path

      def check_sorted
        errors = []
        previous_text = nil

        entries.each do |entry|
          if previous_text && entry.text <= previous_text
            errors << {
              message: "Lines are not sorted at #{entry.filename}:#{entry.line_number}",
              code: "ignore_file_not_in_sequence",
              file: entry.filename,
              line: entry.line_number,
            }
          end

          previous_text = entry.text
        end

        errors
      end

      def patterns
        patterns_and_files[0]
      end

      def files
        patterns_and_files[1]
      end

      private

      def entries
        return @entries if defined? @entries

        lines = begin
                  IO.readlines(root_path.join(path)).map(&:chomp)
                rescue Errno::ENOENT
                  []
                end

        entries = []

        lines.each_with_index do |line, index|
          next if line.empty? || line.start_with?("#")
          entries << Entry.new(
            text: line.chomp,
            filename: path,
            line_number: index + 1,
          )
        end

        @entries = entries
      end

      def patterns_and_files
        @patterns_and_files ||= entries.map(&:text).partition { |text| text.include?("*") }
      end
    end
  end
end
