require 'spec_helper'
require 'example_app'

require 'ronin/web/spider'

describe Ronin::Web::Spider do
  include_context "example App"

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
end
