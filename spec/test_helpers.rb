# frozen_string_literal: true

require 'fileutils'
require 'open3'
require 'tmpdir'

module TestHelpers
  CODEOWNERS_EXECUTABLE = File.expand_path(
    File.join(
      File.dirname(__FILE__),
      "..",
      "bin",
      "check-codeowners",
    )
  )

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
      expect(r.status).to be_success
      expect(r.stdout).to eq("")
      expect(r.stderr).to eq("")
    end
  end

  def run(*args)
    Dir.mktmpdir do |dir|
      @files.each do |file|
        path = File.join(dir, file)
        FileUtils.mkdir_p(File.dirname(path))
        File.open(path, 'w') {}
      end

      # Untested: putting these files in the root, or in "docs".
      write_file(dir, ".github/CODEOWNERS", @codeowners)
      write_file(dir, ".github/CODEOWNERS.ignore", @codeowners_ignore)
      write_file(dir, ".github/VALIDOWNERS", @valid_owners)

      system "git init --quiet && git add .", chdir: dir
      $?.success? or raise "git init / add failed"

      stdout, stderr, status = Open3.capture3(CODEOWNERS_EXECUTABLE, *args, chdir: dir)

      Result.new(stdout, stderr, status)
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
