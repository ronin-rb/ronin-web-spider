require 'spec_helper'
require 'ronin/web/spider/agent'

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
  end
end
