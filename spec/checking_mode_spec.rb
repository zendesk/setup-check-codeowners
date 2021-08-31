require_relative './test_helpers'

RSpec.configure { |c| c.include TestHelpers }

RSpec.describe "check-codeowners checking mode" do

  before do
    setup
  end

  it "doesn't need CODEOWNERS" do
    @codeowners = nil
    @codeowners_ignore = []
    @valid_owners = []
    expect_silent_success { run }
  end

  it "doesn't need CODEOWNERS.ignore" do
    @codeowners = []
    @codeowners_ignore = nil
    @valid_owners = []
    expect_silent_success { run }
  end

  it "doesn't need VALIDOWNERS" do
    @codeowners = []
    @codeowners_ignore = nil
    @valid_owners = []
    expect_silent_success { run }
  end

  it "passes in a simple happy state" do
    create_file "foo.txt"
    add_codeowners "foo.txt @zendesk/a-team"
    add_valid_owner "@zendesk/a-team"
    expect_silent_success { run }
  end

  describe "useless CODEOWNERS lines" do

    before do
      add_codeowners "foo @a/b"
    end

    it "does not check by default" do
      expect_silent_success { run }
    end

    it "warns" do
      r = run "--brute-force"
      aggregate_failures do
        expect(r.status.exitstatus).to eq(0)
        expect(r.stdout).to eq("WARNING: Pattern foo at .github/CODEOWNERS:1 doesn't match any files\n" + help_message)
        expect(r.stderr).to eq("")
      end
    end

    it "turns warnings into errors in --strict mode" do
      r = run "--brute-force", "--strict"
      aggregate_failures do
        expect(r.status.exitstatus).to eq(1)
        expect(r.stdout).to eq("ERROR: Pattern foo at .github/CODEOWNERS:1 doesn't match any files\n" + help_message)
        expect(r.stderr).to eq("")
      end
    end

    it "can be satisifed" do
      create_file("foo")
      expect_silent_success { run "--brute-force" }
    end

  end

  describe "unowned files" do

    before do
      create_file("unowned")
      @codeowners = []
      @codeowners_ignore = []
    end

    it "does not check by default" do
      expect_silent_success { run }
    end

    it "fails if checked" do
      add_codeowners ".github @a/b"
      r = run "--check-unowned"
      aggregate_failures do
        expect(r.status.exitstatus).to eq(1)
        expect(r.stdout).to eq("ERROR: Please add this file to .github/CODEOWNERS: unowned\n" + help_message)
        expect(r.stderr).to eq("")
      end
    end

    it "can be ignored" do
      add_codeowners ".github @a/b"
      add_ignore "unowned"
      expect_silent_success { run "--check-unowned" }
    end

  end

  describe "indenting" do

    describe "is ok" do
      it "passes" do
        add_codeowners "foo      @a/b"
        add_codeowners "fooooo   @a/b"
        expect_silent_success { run }
      end
    end

    describe "is not ok" do
      it "fails" do
        add_codeowners "foo      @a/b"
        add_codeowners "fooooo    @a/b"
        r = run
        aggregate_failures do
          expect(r.status.exitstatus).to eq(1)
          expect(r.stdout).to eq("ERROR: Mismatched indent at .github/CODEOWNERS:2\n" + help_message)
          expect(r.stderr).to eq("")
        end
      end

      it "can be skipped" do
        add_codeowners "foo      @a/b"
        add_codeowners "fooooo    @a/b"
        expect_silent_success { run "--no-check-indent" }
      end
    end

  end

  describe "VALIDOWNERS" do

    describe "missing" do
      it "assumes all owners are valid" do
        add_codeowners "foo1 @org/team1"
        add_codeowners "foo2 @org/team2"
        expect_silent_success { run }
      end
    end

    describe "present" do

      before do
        add_codeowners "foo1 @org/team1"
        add_codeowners "foo2 @org/team2"
        add_valid_owner "@org/team2"
      end

      it "validates" do
        r = run

        aggregate_failures do
          expect(r.status.exitstatus).to eq(1)
          expect(r.stdout).to eq("ERROR: Invalid owner @org/team1 at .github/CODEOWNERS:1\n" + help_message)
          expect(r.stderr).to eq("")
        end
      end

      it "can skip validation" do
        expect_silent_success do
          run "--no-check-valid-owners"
        end
      end

      # VALIDOWNERS does not yet enforce strict ordering
      # i.e. reject duplicate / out-of-order entries.

    end

  end

  describe "non-codeowner lines" do

    it "allows comments and blanks" do
      add_codeowners "# A comment"
      add_codeowners ""
      add_codeowners "file1 @foo/bar"
      add_codeowners ""
      add_codeowners "file2 @foo/bar"

      expect_silent_success { run }
    end

  end

  it "fails on unrecognised lines" do
    add_codeowners "file1 @an/owner"
    add_codeowners "file2"
    add_codeowners "file3 @an/owner"

    r = run

    aggregate_failures do
      expect(r.status.exitstatus).to eq(1)
      expect(r.stdout).to eq("ERROR: Unrecognised line at .github/CODEOWNERS:2\n" + help_message)
      expect(r.stderr).to eq("")
    end
  end

  describe "unused CODEOWNERS.ignore lines" do

    it "fails on an unused line" do
      create_file "dog"
      create_file "fish"
      add_codeowners "* @owner"
      add_ignore "c*"

      r = run "--check-unowned"

      aggregate_failures do
        expect(r.status.exitstatus).to eq(0)
        expect(r.stdout).to eq("WARNING: The following entry in .github/CODEOWNERS.ignore doesn't match any unowned files and should be removed: c*\n" + help_message)
        expect(r.stderr).to eq("")
      end
    end

  end

  describe "json output" do

    it "handles success" do
      create_file "x"
      add_codeowners "x @y"

      r = run "--json"
      require 'json'
      data = JSON.parse(r.stdout)

      expect(r.status).to be_success
      expect(data).to eq({"errors"=>[], "warnings"=>[]})
    end

    it "reports warnings" do
      add_codeowners ".github/* @owner"
      add_ignore "c*"

      r = run "--json", "--strict", "--check-unowned"
      require 'json'
      data = JSON.parse(r.stdout)

      aggregate_failures do
        expect(r.status.exitstatus).to eq(1)
        expect(data["warnings"].length).to eq(0)
        expect(data["errors"].length).to eq(1)
        item = data["errors"].first
        expect(item["code"]).to eq("unused_ignore")
        expect(item["unused_ignore"]).to eq("c*")
      end
    end

    it "reports errors" do
      add_codeowners "bad_line"

      r = run "--json"
      require 'json'
      data = JSON.parse(r.stdout)

      aggregate_failures do
        expect(r.status.exitstatus).to eq(1)
        expect(data["errors"].length).to eq(1)
        item = data["errors"].first
        expect(item["code"]).to eq("unrecognised_line")
        expect(item["entry"]["file"]).to eq(".github/CODEOWNERS")
        expect(item["entry"]["line_number"]).to eq(1)
      end
    end

  end

  describe "CODEOWNERS ordering" do

    it "passes if the file is ordered" do
      add_codeowners "a @owner"
      add_codeowners "b @owner"
      add_codeowners "c @owner"

      expect_silent_success { run }
    end

    it "fails if the file is unordered" do
      add_codeowners "a @owner"
      add_codeowners "c @owner"
      add_codeowners "b @owner"

      r = run

      aggregate_failures do
        expect(r.status.exitstatus).to eq(1)
        expect(r.stdout).to eq("ERROR: Line is duplicated or out of sequence at .github/CODEOWNERS:3\n" + help_message)
        expect(r.stderr).to eq("")
      end
    end

    it "passes if the file is unordered, but --no-check-sorted is used" do
      add_codeowners "a @owner"
      add_codeowners "c @owner"
      add_codeowners "b @owner"

      expect_silent_success { run "--no-check-sorted" }
    end

  end

  describe "CODEOWNERS.ignore ordering" do

    before do
      create_file "a"
      create_file "b"
      create_file "c"
      add_ignore ".github/CODEOWNERS.ignore"
    end

    it "passes if the file is ordered" do
      add_ignore "a"
      add_ignore "b"
      add_ignore "c"

      expect_silent_success { run "--check-unowned" }
    end

    it "fails if the file is unordered" do
      add_ignore "a"
      add_ignore "c"
      add_ignore "b"

      r = run "--check-unowned"

      aggregate_failures do
        expect(r.status.exitstatus).to eq(1)
        expect(r.stdout).to eq("ERROR: Line is duplicated or out of sequence at .github/CODEOWNERS.ignore:4\n" + help_message)
        expect(r.stderr).to eq("")
      end
    end

    it "passes if the file is unordered, but --no-check-sorted is used" do
      add_ignore "a"
      add_ignore "c"
      add_ignore "b"

      expect_silent_success { run "--check-unowned", "--no-check-sorted" }
    end

  end

end
