require 'fileutils'
require 'set'
require 'tmpdir'
require_relative '../src/lib/check_codeowners'

module TestHelpers

  HELP_MESSAGE = "For help, see https://github.com/zendesk/setup-check-codeowners/blob/main/Usage.md\n"

  Result = Struct.new(:stdout, :stderr, :status)

  def setup
    @files = Set.new
    @codeowners = nil
    @codeowners_ignore = nil
    @valid_owners = nil
  end

  def create_file(file)
    @files << file
  end

  def add_codeowners(line)
    @codeowners ||= []
    @codeowners << line
  end

  def add_ignore(line)
    @codeowners_ignore ||= []
    @codeowners_ignore << line
  end

  def add_valid_owner(owner)
    @valid_owners ||= []
    @valid_owners << owner
  end

  def expect_silent_success
    r = yield

    aggregate_failures do
      expect(r.status).to eq(CheckCodeowners::CLI::STATUS_SUCCESS)
      expect(r.stdout).to eq("")
      expect(r.stderr).to eq("")
    end
  end

  def run(*args)
    Dir.mktmpdir do |dir|
      @files.each do |file|
        path = File.join(dir, file)
        FileUtils.mkdir_p(File.dirname(path))
        File.open(path, 'w') { }
      end

      # Untested: putting these files in the root, or in "docs".
      write_file(dir, ".github/CODEOWNERS", @codeowners)
      write_file(dir, ".github/CODEOWNERS.ignore", @codeowners_ignore)
      write_file(dir, ".github/VALIDOWNERS", @valid_owners)

      system "git init --quiet && git add .", chdir: dir
      $?.success? or raise "git init / add failed"

      result = {}
      begin
        $stdout = StringIO.new
        $stderr = StringIO.new

        cli = CheckCodeowners::CLI.new(root_path: dir)
        result[:status] = cli.run(args)
        result[:stdout] = $stdout.string
        result[:stderr] = $stderr.string
      ensure
        $stdout = STDOUT
        $stderr = STDERR
      end

      Result.new(result[:stdout], result[:stderr], result[:status])
    end
  end

  def write_file(dir, path, lines)
    return unless lines

    path = File.join(dir, path)
    FileUtils.mkdir_p(File.dirname(path))
    File.open(path, 'w') do |f|
      lines.each { |line| f.puts(line) }
    end
  end

  def help_message
    HELP_MESSAGE
  end

end
