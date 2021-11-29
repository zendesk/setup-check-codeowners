require_relative './test_helpers'

RSpec.configure { |c| c.include TestHelpers }

RSpec.describe "check-codeowners --who-owns" do

  before do
    setup
  end

  it "reports an owned file" do
    create_file "x1"
    create_file "x2"
    create_file "y"
    add_codeowners "x* @foo/bar"

    r = run "--who-owns", "x2"

    aggregate_failures do
      expect(r.status).to be_success
      expect(r.stdout.lines.map(&:chomp)).to contain_exactly(
        "x2\t@foo/bar",
      )
      expect(r.stderr).to eq("")
    end
  end

  it "reports an unowned file" do
    create_file "x1"
    create_file "x2"
    create_file "y"
    add_codeowners "x* @foo/bar"

    r = run "--who-owns", "y"

    aggregate_failures do
      expect(r.status).to be_success
      expect(r.stdout.lines.map(&:chomp)).to contain_exactly(
        "y\t-",
      )
      expect(r.stderr).to eq("")
    end
  end

  it "reports all files by default" do
    create_file "x1"
    create_file "x2"
    create_file "y"
    add_codeowners "x* @foo/bar"

    r = run "--who-owns"

    aggregate_failures do
      expect(r.status).to be_success
      expect(r.stdout.lines.map(&:chomp)).to contain_exactly(
        ".github/CODEOWNERS\t-",
        "x1\t@foo/bar",
        "x2\t@foo/bar",
        "y\t-",
      )
      expect(r.stderr).to eq("")
    end
  end

  # The order of codeowners entries matters: see
  # https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners#example-of-a-codeowners-file
  # Note that this is somewhat at odds with the default "check sorted" behaviour.
  describe "the order of codeowner entries" do
    it "overrides (test 1)" do
      create_file "x1"
      add_codeowners "x* @foo/bar1"
      add_codeowners "x1 @foo/bar2"

      r = run "--who-owns"

      aggregate_failures do
        expect(r.status).to be_success
        expect(r.stdout.lines.map(&:chomp)).to contain_exactly(
          ".github/CODEOWNERS\t-",
          "x1\t@foo/bar2",
        )
        expect(r.stderr).to eq("")
      end
    end

    it "overrides (test 2)" do
      create_file "x1"
      add_codeowners "x1 @foo/bar2" # The opposite way round
      add_codeowners "x* @foo/bar1"

      r = run "--who-owns"

      aggregate_failures do
        expect(r.status).to be_success
        expect(r.stdout.lines.map(&:chomp)).to contain_exactly(
          ".github/CODEOWNERS\t-",
          "x1\t@foo/bar1", # Different from test 1
        )
        expect(r.stderr).to eq("")
      end
    end
  end

end
