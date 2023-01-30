require 'etc'
require 'tempfile'
require 'tmpdir'

module CheckCodeowners
  class MultiGitLsRunner
    PREFIX_LENGTH = 6

    Input = Struct.new(:pattern, :output_basename)

    # Given some gitignore patterns (as opposed to CODEOWNERS patterns),
    # work out which files match each pattern.

    # The approach here is to use
    # `git ls-files --ignored --exclude=PATTERN` for each pattern, to get
    # git itself to do all the pattern matching.
    #
    # For better performance, we use "xargs --parallel" to run multiple
    # of these in parallel.

    def initialize(patterns, root_path:)
      @inputs = patterns.sort.uniq.each_with_index.map do |pattern, index|
        Input.new(pattern, index.to_s)
      end
      @root_path = root_path
    end

    def run
      return {} if @inputs.empty?

      with_output_dir do
        run_xargs
        outputs_by_pattern
      end
    end

    private

    attr_reader :inputs, :root_path

    def with_output_dir
      Dir.mktmpdir do |tmpdir|
        @output_dir = tmpdir
        yield
      end
    end

    def run_xargs
      # For each pattern to be tested, give 3 arguments to `xargs -n 3`:
      # - the first argument becomes arg0
      # - the second argument becomes $1, and is the pattern
      # - the third argument becomes $2, and is the output file for this pattern

      Tempfile.open do |input_file|
        inputs.each do |input|
          input_file.puts "shell-arg0", input.pattern, File.join(@output_dir, input.output_basename)
        end
        input_file.flush

        system "xargs", "-n", "3", "-P", Etc.nprocessors.to_s,
               "sh", "-c", 'exec git ls-files -z --cached --ignored --exclude "$1" > "$2"',
               chdir: root_path,
               in: input_file.path
        $?.success? or raise "xargs / git ls-files failed"
      end
    end

    def outputs_by_pattern
      inputs.map do |input|
        file = File.join(@output_dir, input.output_basename)
        results = File.read(file).split("\0")
        [input.pattern, results]
      end.to_h
    end
  end
end
