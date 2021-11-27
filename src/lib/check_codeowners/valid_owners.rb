class ValidOwners
  def initialize(path)
    @path = path
  end

  def valid_owners
    @valid_owners ||= parse
  end

  private

  attr_reader :path

  def parse
    begin
      IO.readlines(path).map(&:chomp)
    rescue Errno::ENOENT
      nil
    end
  end
end
