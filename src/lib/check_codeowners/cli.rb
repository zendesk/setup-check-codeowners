require 'pathname'

module CheckCodeowners
  class CLI
    STATUS_SUCCESS = 0
    STATUS_ERROR   = 1

    def initialize(root_path:)
      @root_path = Pathname.new(root_path)
    end

    attr_reader :root_path

    def run(args = ARGV)
      options = CheckCodeowners::GetOptions.new(args)

      repo = CheckCodeowners::Repository::Repository.new(root_path: @root_path)

      if options.who_owns
        CheckCodeowners::Reports.new(repo, options).who_owns
        return STATUS_SUCCESS
      end

      if options.files_owned
        CheckCodeowners::Reports.new(repo, options).files_owned
        return STATUS_SUCCESS
      end

      checker = CheckCodeowners::CheckRunner.new(repo, options)
      checker.show_checks

      if checker.errors?
        STATUS_ERROR
      else
        STATUS_SUCCESS
      end
    end
  end
end
