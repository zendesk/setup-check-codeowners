# frozen_string_literal: true

require_relative './test_helpers'

RSpec.configure { |c| c.include TestHelpers }

RSpec.describe "check-codeowners --files-owned" do
  before do
    setup
  end

  it "can report owned files" do
    create_file "file1"
    create_file "file2"
    create_file "thing"
    add_codeowners "file* @foo/bar"

    r = run "--files-owned", "@foo/bar"

    aggregate_failures do
      expect(r.status).to be_success
      expect(r.stdout.lines.map(&:chomp)).to contain_exactly(
        "file1\t@foo/bar",
        "file2\t@foo/bar",
      )
      expect(r.stderr).to eq("")
    end
  end

  it "can report owned files for multiple owners" do
    create_file "file1"
    create_file "file2"
    create_file "thing"
    create_file "unowned"
    add_codeowners "file* @foo/bar"
    add_codeowners "thing @foo/thing"

    r = run "--files-owned", "@foo/bar", "@foo/thing"

    aggregate_failures do
      expect(r.status).to be_success
      expect(r.stdout.lines.map(&:chomp)).to contain_exactly(
        "file1\t@foo/bar",
        "file2\t@foo/bar",
        "thing\t@foo/thing",
      )
      expect(r.stderr).to eq("")
    end
  end

  it "defaults to no owners" do
    create_file "file1"
    add_codeowners "file* @foo/bar"

    expect_silent_success { run "--files-owned" }
  end
end
