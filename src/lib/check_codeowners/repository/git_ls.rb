require 'open3'
require 'shellwords'
require 'tempfile'

module CheckCodeowners
  module Repository
    class GitLs
      def initialize(root_path:)
        @root_path = root_path
      end

      attr_reader :root_path

      def all_files
        @all_files ||= git_ls_files
      end

      private

      def git_ls_files
        command = "git ls-files -z"
        output, status = Open3.capture2(command, chdir: root_path)
        status.success? or raise "#{command} failed"

        output.split("\0")
      end
    end
  end
end
