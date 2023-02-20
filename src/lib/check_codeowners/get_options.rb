require 'optparse'

module CheckCodeowners
  class GetOptions
    def initialize(argv)
      @debug = false
      @show_json = false
      @strict = false
      @find_no_matches = false
      @who_owns = false
      @files_owned = false
      @check_unowned = false
      @should_check_indent = true
      @should_check_sorted = true
      @should_check_valid_owners = true
      read_options(argv)
      validate
    end

    attr_reader :debug, :show_json, :strict, :find_no_matches,
                :who_owns, :files_owned,
                :check_unowned, :should_check_indent, :should_check_sorted, :should_check_valid_owners,
                :args

    private

    attr_writer :debug, :show_json, :strict, :find_no_matches,
                :who_owns, :files_owned,
                :check_unowned, :should_check_indent, :should_check_sorted, :should_check_valid_owners,
                :args

    def read_options(argv)
      parser = OptionParser.new do |opts|
        opts.banner = "Usage: check-codeowners [options] [arguments]"

        opts.on("-j", "--json", "Show results as JSON") do
          self.show_json = true
        end
        opts.on("-s", "--strict", "Treat warnings as errors") do
          self.strict = true
        end
        opts.on("--find-no-matches", "Find entries which do not match any files") do
          self.find_no_matches = true
        end
        opts.on("--no-check-indent", "Do not require equal indenting") do |value|
          self.should_check_indent = value
        end
        opts.on("--no-check-sorted", "Do not require sorted entries") do |value|
          self.should_check_sorted = value
        end
        opts.on("--no-check-valid-owners", "Do not check owners against VALIDOWNERS") do |value|
          self.should_check_valid_owners = value
        end
        opts.on(
          "--who-owns",
          "Treat arguments as a list of files; show who owns each file, then exit." \
          " If no arguments are given, all files are shown. Incompatible with" \
          " --files-owned."
        ) do
          self.who_owns = true
        end
        opts.on(
          "--files-owned",
          "Treat arguments as a list of owners; show what files they own, then exit." \
          " Incompatible with --who-owns."
        ) do
          self.files_owned = true
        end
        opts.on(
          "--check-unowned",
          "Checks if there are new files that are not owned"
        ) do
          self.check_unowned = true
        end
        opts.on("-d", "--debug", "Include debug output; implies --json") do
          self.debug = true
          self.show_json = true
        end
      end

      argv = [*argv]
      parser.parse!(argv)
      @args = argv
    end

    def validate
      if who_owns && files_owned
        $stderr.puts "Invalid usage. Try check-codeowners --help"
        exit 2
      end

      if !who_owns && !files_owned && args.any?
        $stderr.puts "Invalid usage. Try check-codeowners --help"
        exit 2
      end
    end
  end
end
