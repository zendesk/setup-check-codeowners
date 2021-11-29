class OwnerEntry < Entry
  def initialize(text:, file:, line_number:, pattern:, owners:, indent:)
    super(text: text, file: file, line_number: line_number)
    @pattern = pattern
    @owners = owners
    @indent = indent
  end

  attr_reader :pattern, :owners, :indent

  def to_h
    super.merge(pattern: pattern, owners: owners, indent: indent)
  end
end
