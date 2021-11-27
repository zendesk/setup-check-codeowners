module CheckCodeowners
  module Repository
    class Entry
      def initialize(text:, file:, line_number:)
        @text = text
        @file = file
        @line_number = line_number
      end

      attr_reader :text, :file, :line_number

      def to_json(*args)
        to_h.to_json(*args)
      end

      def to_h
        { text: text, file: file, line_number: line_number }
      end
    end
  end
end
