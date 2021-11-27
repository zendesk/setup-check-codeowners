module CheckCodeowners
  module Repository
    class Codeowners
      def initialize(path)
        @path = path
        parse
      end

      attr_reader :path, :entries, :errors

      def owner_entries
        @owner_entries ||= entries.select { |e| e.is_a?(OwnerEntry) }
      end

      private

      def parse
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

        @entries = entries
        @errors = errors
      end
    end
  end
end
