class Repository
  CODEOWNERS_PATHS = [
    "CODEOWNERS",
    "docs/CODEOWNERS",
    ".github/CODEOWNERS",
  ].freeze

  # The repository directory is always the current directory.
  # Maybe that could be changed one day.

  def codeowners_file
    @codeowners_file ||= find_codeowners_file
  end

  def codeowners_ignore_file
    @codeowners_ignore_file ||= codeowners_file + ".ignore"
  end

  def codeowners_entries
    @codeowners_entries ||= Parsers.new.parse_codeowners_file(codeowners_file)
  end

  def codeowners_ignore
    @codeowners_ignore ||= CodeownersIgnore.new(codeowners_ignore_file)
  end

  def valid_owners
    @valid_owners ||= ValidOwners.new(validowners_file)
  end

  private

  def validowners_file
    @validowners_file ||= codeowners_file.sub(/CODEOWNERS$/, "VALIDOWNERS")
  end

  # https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners#codeowners-file-location
  def find_codeowners_file
    CODEOWNERS_PATHS.find do |path|
      File.exist?(path)
    end || CODEOWNERS_PATHS.last
  end
end
