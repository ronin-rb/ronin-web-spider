require 'spec_helper'
require 'ronin/web/spider/archive'

require 'tmpdir'

describe Ronin::Web::Spider::Archive do
  let(:root) { File.join(Dir.mktmpdir('ronin-web-spider')) }

  subject { described_class.new(root) }

  describe "#initialize" do
    it "must set #root" do
      expect(subject.root).to eq(root)
    end
  end

  describe ".open" do
    subject { described_class.open(root) }

    it "must return a new #{described_class}" do
      expect(subject).to be_kind_of(described_class)
    end

    context "when given a block" do
      it "must yield the new #{described_class}" do
        expect { |b|
          described_class.open(root,&b)
        }.to yield_with_args(described_class)
      end
    end

    context "when the root directory does not exist" do
      let(:root) { File.join(super(),'does-not-exist-yet') }

      it "must create the given root directory" do
        described_class.open(root)

        expect(File.directory?(root)).to be(true)
      end
    end

    context "when the root directory does exist" do
      let(:root) { File.join(super(),'does-not-exist-yet') }

      before { FileUtils.mkdir(root) }

      it "must not raise an error" do
        expect {
          described_class.open(root)
        }.to_not raise_error
      end
    end
  end

  describe "#write" do
    let(:url)  { URI('https://example.com/foo/bar.html') }
    let(:body) { 'test file' }

    before { subject.write(url,body) }

    it "must automatically create parent directory" do
      expect(File.directory?(File.join(root,'foo'))).to be(true)
    end

    it "must write the body into the file" do
      expect(File.read(File.join(root,'foo','bar.html'))).to eq(body)
    end

    context "when the URL has a query string" do
      let(:url) { URI('https://example.com/foo/bar.php?q=1') }

      it "must include the query string as part of the file name" do
        expect(File.read(File.join(root,'foo','bar.php?q=1'))).to eq(body)
      end
    end

    context "when the URL path ends with a '/'" do
      let(:url) { URI('https://example.com/foo/bar/') }

      it "must write the body to an index.html file within the URL's path" do
        expect(File.read(File.join(root,'foo','bar','index.html'))).to eq(body)
      end
    end
  end

  describe "#to_s" do
    it "must return the root directory" do
      expect(subject.to_s).to eq(root)
    end
  end
end
