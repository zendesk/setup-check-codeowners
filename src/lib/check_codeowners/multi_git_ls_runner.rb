require 'etc'
require 'tempfile'
require 'tmpdir'

module CheckCodeowners
  class MultiGitLsRunner
    PREFIX_LENGTH = 6

    def initialize(patterns)
      # Each arg to the script will be "<output_file>:<pattern>"
      @inputs = patterns.sort.uniq.each_with_index.map do |pattern, index|
        [ pattern, "%0#{PREFIX_LENGTH}d" % index ]
      end
    end

    def run
      return {} if @inputs.empty?

      with_output_dir do
        run_xargs
        outputs_by_pattern
      end
    end

    private

    attr_reader :inputs

    def with_output_dir
      Dir.mktmpdir do |tmpdir|
        @output_dir = tmpdir
        yield
      end
    end

    def run_xargs
      # For each pattern to be tested, give 3 arguments to xargs -n 3:
      # - the first argument becomes arg0
      # - the second argument becomes $1, and is the pattern
      # - the third argument becomes $2, and is the output file for this pattern

      Tempfile.open do |input_file|
        inputs.each do |pattern, output_file|
          input_file.puts "shell-arg0", pattern, File.join(@output_dir, output_file)
        end
        input_file.flush

        system "xargs", "-n", "3", "-P", Etc.nprocessors.to_s,
               "sh", "-c", 'exec git ls-files -z --cached --ignored --exclude "$1" > "$2"',
               in: input_file.path
        $?.success? or raise "xargs / git ls-files failed"
      end
    end

    def outputs_by_pattern
      inputs.map do |pattern, output_file|
        file = File.join(@output_dir, output_file)
        results = File.read(file).split("\0")
        [pattern, results]
      end.to_h
    end
  end
end
