require 'spec_helper'
require 'ronin/web/spider/git_archive'

require 'tmpdir'

describe Ronin::Web::Spider::GitArchive do
  let(:root) { File.join(Dir.mktmpdir('ronin-web-spider')) }

  describe ".open" do
    subject { described_class }

    context "when the root directory does not already exist" do
      let(:root) { File.join(Dir.tmpdir,'ronin-web-spider-new-dir') }

      it "must run `git init` on the new archive directory" do
        subject.open(root)

        expect(File.directory?(File.join(root,'.git'))).to be(true)
      end

      after { FileUtils.rm_r(root) }
    end

    context "when the root directory already exists" do
      context "but does not contain a .git directory" do
        it "must run `git init` within the root directory" do
          subject.open(root)

          expect(File.directory?(File.join(root,'.git'))).to be(true)
        end
      end
    end
  end

  subject { described_class.open(root) }

  describe "#git?" do
    subject { described_class.new(root) }

    context "when the archive directory contains a .git directory" do
      before do
        FileUtils.mkdir(File.join(root,'.git'))
      end

      it "must return true" do
        expect(subject.git?).to be(true)
      end
    end

    context "when the archive directory does not contains a .git directory" do
      it "must return false" do
        expect(subject.git?).to be(false)
      end
    end
  end

  describe "#init" do
    it "must run the 'git init' command" do
      expect(subject).to receive(:system).with('git','-C',root,'init').and_return(true)

      subject.init
    end

    context "when the 'git init' command fails" do
      it do
        allow(subject).to receive(:system).with('git','-C',root,'init').and_return(false)

        expect {
          subject.init
        }.to raise_error(Ronin::Web::Spider::GitError,"git command failed: git -C #{root} init")
      end
    end

    context "when 'git' is not installed" do
      it do
        allow(subject).to receive(:system).with('git','-C',root,'init').and_return(nil)

        expect {
          subject.init
        }.to raise_error(Ronin::Web::Spider::GitError,"the git command was not found")
      end
    end
  end

  describe "#write" do
    let(:url)  { URI('https://example.com/foo/bar.html') }
    let(:body) { 'test file' }

    it "must automatically create parent directory" do
      subject.write(url,body)

      expect(File.directory?(File.join(root,'foo'))).to be(true)
    end

    it "must write the body into the file" do
      subject.write(url,body)

      expect(File.read(File.join(root,'foo','bar.html'))).to eq(body)
    end

    it "must add the file using `git add`" do
      absolute_path = File.join(root,'foo','bar.html')

      expect(subject).to receive(:system).with(
        'git', '-C', root, 'add', absolute_path
      ).and_return(true)

      subject.write(url,body)
    end
  end

  describe "#commit" do
    let(:message) { 'commit message' }

    context "when a block is given" do
      it "must yield control before calling `git commit -m ...` with the commit message" do
        expect(subject).to receive(:system).with(
          'git', '-C', root, 'commit', '-m', message
        ).and_return(true)

        expect { |b|
          subject.commit(message,&b)
        }.to yield_with_args(subject)
      end
    end

    context "when no block is given" do
      it "must not yield and call `git commit -m ...` with the commit message" do
        expect(subject).to receive(:system).with(
          'git', '-C', root, 'commit', '-m', message
        ).and_return(true)

        subject.commit(message)
      end
    end
  end
end
