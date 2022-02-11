require 'spec_helper'
require 'example_app'

require 'ronin/web/spider'

describe Ronin::Web::Spider do
  include_context "example App"

  shared_context "Example Site" do
    module TestAgentSite
      class ExampleApp < Sinatra::Base

        set :host, 'example.com'
        set :port, 80

        get '/' do
          '<html><body>should not get here</body></html>'
        end

        get '/entry-point' do
          <<~HTML
            <html>
              <body>
                <a href="/link1">link1</a>
                <a href="http://other.com/offsite-link">offsite link</a>
                <a href="/link2">link2</a>
              </body>
            </html>
          HTML
        end

        get '/link1' do
          '<html><body>got here</body></html>'
        end

        get '/link2' do
          '<html><body>got here</body></html>'
        end

      end
    end

    subject { described_class }

    let(:host) { 'example.com' }
    let(:url)  { URI("http://#{host}/entry-point") }

    let(:app) { TestAgentSite::ExampleApp }

    before do
      stub_request(:any, /#{Regexp.escape(host)}/).to_rack(app)
    end
  end

  shared_context "Example Host" do
    module TestAgentHost
      class ExampleApp < Sinatra::Base

        set :host, 'example.com'
        set :port, 80

        get '/' do
          <<~HTML
            <html>
              <body>
                <a href="/link1">link1</a>
                <a href="http://other.com/offsite-link">offsite link</a>
                <a href="/link2">link2</a>
              </body>
            </html>
          HTML
        end

        get '/link1' do
          '<html><body>got here</body></html>'
        end

        get '/link2' do
          '<html><body>got here</body></html>'
        end

      end
    end

    subject { described_class }

    let(:host) { 'example.com' }
    let(:app)  { TestAgentHost::ExampleApp }

    before do
      stub_request(:any, /#{Regexp.escape(host)}/).to_rack(app)
    end
  end

  shared_context "Example Domain" do
    module TestAgentDomain
      class ExampleApp < Sinatra::Base

        set :host, 'example.com'
        set :port, 80

        get '/' do
          <<~HTML
            <html>
              <body>
                <a href="/link1">link1</a>
                <a href="http://sub.example.com/subdomain-link">subdomain link</a>
                <a href="/link2">link2</a>
              </body>
            </html>
          HTML
        end

        get '/link1' do
          '<html><body>got here</body></html>'
        end

        get '/link2' do
          '<html><body>got here</body></html>'
        end

      end

      class SubDomainApp < Sinatra::Base

        set :host, 'sub.example.com'
        set :port, 80

        get '/subdomain-link' do
          '<html><body>should get here</body></html>'
        end

      end
    end

    subject { described_class }

    let(:domain)        { 'example.com' }
    let(:domain_app)    { TestAgentDomain::ExampleApp }

    let(:subdomain)     { 'sub.example.com' }
    let(:subdomain_app) { TestAgentDomain::SubDomainApp }

    before do
      stub_request(:any, /#{Regexp.escape(subdomain)}/).to_rack(subdomain_app)
      stub_request(:any, /#{Regexp.escape(domain)}/).to_rack(domain_app)
    end
  end

  describe ".start_at" do
    module TestAgentStartAt
      class ExampleApp < Sinatra::Base

        set :host, 'example.com'
        set :port, 80

        get '/' do
          '<html><body>should not get here</body></html>'
        end

        get '/entry-point' do
          <<~HTML
          <html>
            <body>
              <a href="/link1">link1</a>
              <a href="http://other.com/offsite-link">offsite link</a>
              <a href="/link2">link2</a>
            </body>
          </html>
          HTML
        end

        get '/link1' do
          '<html><body>got here</body></html>'
        end

        get '/link2' do
          '<html><body>got here</body></html>'
        end
      end

      class OtherApp < Sinatra::Base

        set :host, 'other.com'
        set :port, 80

        get '/offsite-link' do
          '<html><body>should not get here</body></html>'
        end

      end
    end

    subject { described_class }

    let(:host)       { 'example.com' }
    let(:other_host) { 'other.com'   }
    let(:url)        { URI("http://#{host}/entry-point") }

    let(:app)       { TestAgentStartAt::ExampleApp }
    let(:other_app) { TestAgentStartAt::OtherApp   }

    before do
      stub_request(:any, /#{Regexp.escape(host)}/).to_rack(app)
      stub_request(:any, /#{Regexp.escape(other_host)}/).to_rack(other_app)
    end

    it "must spider the website starting at the given URL" do
      agent = subject.start_at(url)

      expect(agent.history).to be == Set[
        URI("http://#{host}/entry-point"),
        URI("http://#{host}/link1"),
        URI("http://#{other_host}/offsite-link"),
        URI("http://#{host}/link2")
      ]
    end
  end

  describe ".site" do
    include_examples "Example Site"

    it "must spider the website starting at the given URL" do
      agent = subject.site(url)

      expect(agent.history).to be == Set[
        URI("http://#{host}/entry-point"),
        URI("http://#{host}/link1"),
        URI("http://#{host}/link2")
      ]
    end
  end

  describe ".host" do
    include_examples "Example Host"

    it "must spider the website starting at the given URL" do
      agent = subject.host(host)

      # XXX: for some reason Set#== was returning false, so convert to an Array
      expect(agent.history.to_a).to be == [
        URI("http://#{host}/"),
        URI("http://#{host}/link1"),
        URI("http://#{host}/link2")
      ]
    end
  end

  describe ".domain" do
    include_examples "Example Domain"

    it "must spider the domain and subdomains starting at the given domain" do
      agent = subject.domain(domain)

      # XXX: for some reason Set#== was returning false, so convert to an Array
      expect(agent.history.to_a).to be == [
        URI("http://#{domain}/"),
        URI("http://#{domain}/link1"),
        URI("http://#{subdomain}/subdomain-link"),
        URI("http://#{domain}/link2")
      ]
    end
  end

  describe ".spider" do
    context "when given the site: keyword argument" do
      include_context "Example Site"

      it "must spider the site and return all spidered URLs" do
        agent = subject.spider(site: url)

        expect(agent.history).to be == Set[
          URI("http://#{host}/entry-point"),
          URI("http://#{host}/link1"),
          URI("http://#{host}/link2")
        ]
      end
    end

    context "when given the host: keyword argument" do
      include_context "Example Host"

      it "must spider the host and return all spidered URLs" do
        agent = subject.spider(host: host)

        # XXX: for some reason Set#== was returning false, so convert to an
        # Array
        expect(agent.history.to_a).to be == [
          URI("http://#{host}/"),
          URI("http://#{host}/link1"),
          URI("http://#{host}/link2")
        ]
      end
    end

    context "when given the domain: keyword argument" do
      include_context "Example Domain"

      it "must spider the domain and return all spidered URLs" do
        agent = subject.spider(domain: domain)

        # XXX: for some reason Set#== was returning false, so convert to an
        # Array
        expect(agent.history.to_a).to be == [
          URI("http://#{domain}/"),
          URI("http://#{domain}/link1"),
          URI("http://#{subdomain}/subdomain-link"),
          URI("http://#{domain}/link2")
        ]
      end
    end
  end

  describe ".every_url" do
    context "when given the site: keyword argument" do
      include_context "Example Site"

      it "must spider the site and return all spidered URLs" do
        expect { |b|
          subject.every_url(site: url, &b)
        }.to yield_successive_args(
          URI("http://#{host}/entry-point"),
          URI("http://#{host}/link1"),
          URI("http://#{host}/link2")
        )
      end
    end

    context "when given the host: keyword argument" do
      include_context "Example Host"

      it "must spider the host and return all spidered URLs" do
        # XXX: for some reason Set#== was returning false, so convert to an
        # Array
        expect { |b|
          subject.every_url(host: host, &b)
        }.to yield_successive_args(
          URI("http://#{host}/"),
          URI("http://#{host}/link1"),
          URI("http://#{host}/link2")
        )
      end
    end

    context "when given the domain: keyword argument" do
      include_context "Example Domain"

      it "must spider the domain and return all spidered URLs" do
        # XXX: for some reason Set#== was returning false, so convert to an
        # Array
        expect { |b|
          subject.every_url(domain: domain, &b)
        }.to yield_successive_args(
          URI("http://#{domain}/"),
          URI("http://#{domain}/link1"),
          URI("http://#{subdomain}/subdomain-link"),
          URI("http://#{domain}/link2")
        )
      end
    end
  end

  describe ".every_url_like" do
    let(:pattern) { /link/ }

    context "when given the site: keyword argument" do
      include_context "Example Site"

      it "must spider the site and return all spidered URLs" do
        expect { |b|
          subject.every_url_like(pattern, site: url, &b)
        }.to yield_successive_args(
          URI("http://#{host}/link1"),
          URI("http://#{host}/link2")
        )
      end
    end

    context "when given the host: keyword argument" do
      include_context "Example Host"

      it "must spider the host and return all spidered URLs" do
        # XXX: for some reason Set#== was returning false, so convert to an
        # Array
        expect { |b|
          subject.every_url_like(pattern, host: host, &b)
        }.to yield_successive_args(
          URI("http://#{host}/link1"),
          URI("http://#{host}/link2")
        )
      end
    end

    context "when given the domain: keyword argument" do
      include_context "Example Domain"

      it "must spider the domain and return all spidered URLs" do
        # XXX: for some reason Set#== was returning false, so convert to an
        # Array
        expect { |b|
          subject.every_url_like(pattern, domain: domain, &b)
        }.to yield_successive_args(
          URI("http://#{domain}/link1"),
          URI("http://#{subdomain}/subdomain-link"),
          URI("http://#{domain}/link2")
        )
      end
    end
  end

  describe ".urls" do
    context "when no block is given" do
      context "when given the site: keyword argument" do
        include_context "Example Site"

        it "must spider the site and return all spidered URLs" do
          expect(subject.urls(site: url)).to be == Set[
            URI("http://#{host}/entry-point"),
            URI("http://#{host}/link1"),
            URI("http://#{host}/link2")
          ]
        end

        context "and the like: keyword argument is given" do
          let(:like) { /link/ }

          it "must spider the site and filter the URLs with the pattern" do
            expect(subject.urls(site: url, like: like)).to be == Set[
              URI("http://#{host}/link1"),
              URI("http://#{host}/link2")
            ]
          end
        end
      end

      context "when given the host: keyword argument" do
        include_context "Example Host"

        it "must spider the host and return all spidered URLs" do
          # XXX: for some reason Set#== was returning false, so convert to an
          # Array
          expect(subject.urls(host: host).to_a).to be == [
            URI("http://#{host}/"),
            URI("http://#{host}/link1"),
            URI("http://#{host}/link2")
          ]
        end

        context "and the like: keyword argument is given" do
          let(:like) { /link/ }

          it "must spider the site and filter the URLs with the pattern" do
            # XXX: for some reason Set#== was returning false, so convert to an
            # Array
            expect(subject.urls(host: host, like: like).to_a).to be == [
              URI("http://#{host}/link1"),
              URI("http://#{host}/link2")
            ]
          end
        end
      end

      context "when given the domain: keyword argument" do
        include_context "Example Domain"

        it "must spider the domain and return all spidered URLs" do
          # XXX: for some reason Set#== was returning false, so convert to an
          # Array
          expect(subject.urls(domain: domain).to_a).to be == [
            URI("http://#{domain}/"),
            URI("http://#{domain}/link1"),
            URI("http://#{subdomain}/subdomain-link"),
            URI("http://#{domain}/link2")
          ]
        end

        context "and the like: keyword argument is given" do
          let(:like) { /link/ }

          it "must spider the site and filter the URLs with the pattern" do
            # XXX: for some reason Set#== was returning false, so convert to an
            # Array
            expect(subject.urls(domain: domain, like: like).to_a).to be == [
              URI("http://#{domain}/link1"),
              URI("http://#{subdomain}/subdomain-link"),
              URI("http://#{domain}/link2")
            ]
          end
        end
      end
    end

    context "when a block is given" do
      context "when given the site: keyword argument" do
        include_context "Example Site"

        it "must spider the site and return all spidered URLs" do
          expect { |b|
            subject.urls(site: url, &b)
          }.to yield_successive_args(
            URI("http://#{host}/entry-point"),
            URI("http://#{host}/link1"),
            URI("http://#{host}/link2")
          )
        end

        context "and the like: keyword argument is given" do
          let(:like) { /link/ }

          it "must spider the site and filter the URLs with the pattern" do
            expect { |b|
              subject.urls(site: url, like: like, &b)
            }.to yield_successive_args(
              URI("http://#{host}/link1"),
              URI("http://#{host}/link2")
            )
          end
        end
      end

      context "when given the host: keyword argument" do
        include_context "Example Host"

        it "must spider the host and return all spidered URLs" do
          # XXX: for some reason Set#== was returning false, so convert to an
          # Array
          expect { |b|
            subject.urls(host: host, &b)
          }.to yield_successive_args(
            URI("http://#{host}/"),
            URI("http://#{host}/link1"),
            URI("http://#{host}/link2")
          )
        end

        context "and the like: keyword argument is given" do
          let(:like) { /link/ }

          it "must spider the site and filter the URLs with the pattern" do
            # XXX: for some reason Set#== was returning false, so convert to an
            # Array
            expect { |b|
              subject.urls(host: host, like: like, &b)
            }.to yield_successive_args(
              URI("http://#{host}/link1"),
              URI("http://#{host}/link2")
            )
          end
        end
      end

      context "when given the domain: keyword argument" do
        include_context "Example Domain"

        it "must spider the domain and return all spidered URLs" do
          # XXX: for some reason Set#== was returning false, so convert to an
          # Array
          expect { |b|
            subject.urls(domain: domain, &b)
          }.to yield_successive_args(
            URI("http://#{domain}/"),
            URI("http://#{domain}/link1"),
            URI("http://#{subdomain}/subdomain-link"),
            URI("http://#{domain}/link2")
          )
        end

        context "and the like: keyword argument is given" do
          let(:like) { /link/ }

          it "must spider the site and filter the URLs with the pattern" do
            # XXX: for some reason Set#== was returning false, so convert to an
            # Array
            expect { |b|
              subject.urls(domain: domain, like: like, &b)
            }.to yield_successive_args(
              URI("http://#{domain}/link1"),
              URI("http://#{subdomain}/subdomain-link"),
              URI("http://#{domain}/link2")
            )
          end
        end
      end
    end
  end
end
