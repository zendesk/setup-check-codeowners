module CheckCodeowners
  module Repository
    class ValidOwners
      def initialize(path, root_path:)
        @path = path
        @root_path = root_path
      end

      def valid_owners
        @valid_owners ||= parse
      end

      private

      attr_reader :path, :root_path

      def parse
        begin
          IO.readlines(root_path.join(path)).map(&:chomp)
        rescue Errno::ENOENT
          nil
        end
      end
    end
  end
end
