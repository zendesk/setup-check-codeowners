require 'shellwords'
require 'tempfile'

module CheckCodeowners
  module Repository
    class GitLs
      def all_files
        @all_files ||= git_ls_files(args: [])
      end

      private

      def git_ls_files(args:)
        output = `git ls-files -z #{Shellwords.shelljoin(args)}`
        $?.success? or raise "git ls-files #{args.inspect} failed"

        output.split("\0")
      end
    end
  end
end
