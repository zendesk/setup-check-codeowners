require_relative './test_helpers'

require 'json'

RSpec.configure { |c| c.include TestHelpers }

RSpec.describe "check-codeowners --debug" do

  before do
    setup
  end

  it "can debug" do
    create_file "x1"
    create_file "x2"
    create_file "y"
    add_codeowners "x* @foo/bar"

    r0 = run "--json", "--brute-force"
    expect(r0.status).to be_success
    data0 = JSON.parse(r0.stdout)

    r1 = run "--debug", "--json", "--brute-force"

    aggregate_failures do
      expect(r1.status).to be_success
      expect(r1.stderr).to eq("")
    end

    # --debug output isn't documented, so it's not important that it's exactly these keys,
    # but it's a canary in case the output changes unexpectedly.
    data1 = JSON.parse(r1.stdout)
    expect(data1.keys - data0.keys).to contain_exactly("entries", "owner_entries", "all_files", "match_map")
  end

end
