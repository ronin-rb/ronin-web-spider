require 'spec_helper'
require 'ronin/web/spider/agent'

require 'webmock/rspec'
require 'sinatra/base'

describe Ronin::Web::Spider::Agent do
  describe "#initialize" do
    context "when ENV['RONIN_HTTP_PROXY'] is set" do
      let(:proxy_host) { 'example.com' }
      let(:proxy_port) { 8080 }

      before do
        ENV['RONIN_HTTP_PROXY'] = "http://#{proxy_host}:#{proxy_port}"
      end

      it "must parse ENV['RONIN_HTTP_USER_AGENT'] and set #proxy" do
        expect(subject.proxy).to be_kind_of(Spidr::Proxy)
        expect(subject.proxy.host).to eq(proxy_host)
        expect(subject.proxy.port).to eq(proxy_port)
      end

      after { ENV.delete('RONIN_HTTP_PROXY') }
    end

    context "when ENV['RONIN_HTTP_USER_AGENT'] is set" do
      let(:user_agent) { 'Foo Bar' }

      before { ENV['RONIN_HTTP_USER_AGENT'] = user_agent }

      it "must default #user_agent to ENV['RONIN_HTTP_USER_AGENT']" do
        expect(subject.user_agent).to eq(user_agent)
      end

      after { ENV.delete('RONIN_HTTP_USER_AGENT') }
    end

    it "must default #visited_hosts to nil" do
      expect(subject.visited_hosts).to be(nil)
    end
  end

  describe "#every_host" do
    module TestAgentEveryHost
      class Host1 < Sinatra::Base

        set :host, 'host1.example.com'
        set :port, 80

        get '/' do
          <<~HTML
          <html>
            <body>
              <a href="/link1">link1</a>
              <a href="http://host2.example.com/offsite-link">offsite link</a>
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

      class Host2 < Sinatra::Base

        set :host, 'host2.example.com'
        set :port, 80

        get '/offsite-link' do
          '<html><body>should not get here</body></html>'
        end

      end
    end

    let(:host1) { 'host1.example.com' }
    let(:host2) { 'host2.example.com'   }

    let(:host1_app) { TestAgentEveryHost::Host1 }
    let(:host2_app) { TestAgentEveryHost::Host2 }

    before do
      stub_request(:any, /#{Regexp.escape(host1)}/).to_rack(host1_app)
      stub_request(:any, /#{Regexp.escape(host2)}/).to_rack(host2_app)
    end

    it "must yield every newly discovered hostname while spidering" do
      yielded_hosts = []

      subject.every_host do |host|
        yielded_hosts << host
      end

      subject.start_at("http://#{host1}/")

      expect(yielded_hosts).to eq([host1, host2])
    end

    it "must popualte #visited_hosts" do
      subject.every_host { |host| }
      subject.start_at("http://#{host1}/")

      expect(subject.visited_hosts).to be_kind_of(Set)
      expect(subject.visited_hosts.entries).to eq([host1, host2])
    end
  end
end
