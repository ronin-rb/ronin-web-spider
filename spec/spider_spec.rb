require 'spec_helper'
require 'ronin/web/spider'

describe Ronin::Web::Spider do
  describe ".start_at" do
    let(:url)     { "https://example.com/" }
    let(:options) { {options: :here}       }

    it "must call Agent.start_at" do
      expect(described_class::Agent).to receive(:start_at).with(url,options)

      subject.start_at(url,options)
    end
  end

  describe ".host" do
    let(:host)    { "www.example.com/" }
    let(:options) { {options: :here}       }

    it "must call Agent.host" do
      expect(described_class::Agent).to receive(:host).with(host,options)

      subject.host(host,options)
    end
  end

  describe ".site" do
    let(:site)    { "www.example.com/" }
    let(:options) { {options: :here}       }

    it "must call Agent.site" do
      expect(described_class::Agent).to receive(:site).with(site,options)

      subject.site(site,options)
    end
  end

  describe ".domain" do
    let(:domain)    { "www.example.com/" }
    let(:options) { {options: :here}       }

    it "must call Agent.domain" do
      expect(described_class::Agent).to receive(:domain).with(domain,options)

      subject.domain(domain,options)
    end
  end
end
