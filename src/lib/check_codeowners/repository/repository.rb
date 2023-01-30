module CheckCodeowners
  module Repository
    class Repository
      CODEOWNERS_PATHS = [
        "CODEOWNERS",
        "docs/CODEOWNERS",
        ".github/CODEOWNERS",
      ].freeze

      def initialize(root_path:)
        @root_path = root_path
      end

      attr_reader :root_path

      def git_ls
        @git_ls ||= GitLs.new(root_path: root_path)
      end

      def individual_pattern_checker
        @individual_pattern_checker ||= IndividualPatternChecker.new(codeowners.owner_entries, root_path: root_path)
      end

      def codeowners
        @codeowners ||= Codeowners.new(codeowners_file, root_path: root_path)
      end

      def codeowners_ignore
        @codeowners_ignore ||= CodeownersIgnore.new(codeowners_ignore_file, root_path: root_path)
      end

      def valid_owners
        @valid_owners ||= ValidOwners.new(validowners_file, root_path: root_path)
      end

      private

      def codeowners_file
        @codeowners_file ||= find_codeowners_file
      end

      def codeowners_ignore_file
        @codeowners_ignore_file ||= codeowners_file + ".ignore"
      end

      def validowners_file
        @validowners_file ||= codeowners_file.sub(/CODEOWNERS$/, "VALIDOWNERS")
      end

      # https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners#codeowners-file-location
      def find_codeowners_file
        CODEOWNERS_PATHS.find do |path|
          root_path.join(path).exist?
        end || CODEOWNERS_PATHS.last
      end
    end
  end
end
