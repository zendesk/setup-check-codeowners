require 'etc'
require 'shellwords'
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
      with_output_dir do
        with_splitter_script do
          run_xargs
          outputs_by_pattern
        end
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

    def with_splitter_script
      ENV['OUTPUT_DIR'] = @output_dir
      @splitter = File.expand_path("check-codeowners-splitter", File.dirname(__FILE__))
      yield
    end

    def run_xargs
      Tempfile.open do |input_file|
        inputs.each do |pattern, output_file|
          input_file.puts "#{output_file}:#{pattern}"
        end
        input_file.flush

        system "xargs", "-n", "1", "-P", Etc.nprocessors.to_s, @splitter,
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
