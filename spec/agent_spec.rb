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

  # TODO: need to figure out how to test #every_cert using webmock.
  describe "#every_cert"
  
  describe "#every_favicon" do
    module TestAgentEveryHost
      class TestApp < Sinatra::Base

        set :host, 'example.com'
        set :port, 80

        get '/' do
          <<~HTML
          <html>
            <head>
              <link rel="favicon" href="/favicon1.ico" type="image/x-icon"/>
            </head>
            <body>
              <a href="/link1">link1</a>
              <a href="http://host2.example.com/offsite-link">offsite link</a>
              <a href="/link2">link2</a>
            </body>
          </html>
          HTML
        end

        get '/favicon1.ico' do
          content_type 'image/x-icon'

          "favicon1"
        end

        get '/favicon2.ico' do
          content_type 'image/vnd.microsoft.icon'

          "favicon2"
        end

        get '/link1' do
          '<html><body>got here</body></html>'
        end

        get '/link2' do
          <<~HTML
          <html>
            <head>
              <link rel="favicon" href="/favicon2.ico" type="image/x-icon"/>
            </head>
            <body>got here</body>
          </html>
          HTML
        end
      end
    end

    let(:host) { 'example.com' }

    let(:test_app) { TestAgentEveryHost::TestApp }

    before do
      stub_request(:any, /#{Regexp.escape(host)}/).to_rack(test_app)
    end

    it "must yield Spidr::Page objects for each encountered .ico file" do
      yielded_favicons = []

      subject.every_favicon do |favicon|
        yielded_favicons << favicon
      end

      subject.start_at("http://#{host}/")

      expect(yielded_favicons).to_not be_empty

      expect(yielded_favicons[0]).to be_kind_of(Spidr::Page)
      expect(yielded_favicons[0].content_type).to eq('image/x-icon')
      expect(yielded_favicons[0].url).to eq(URI("http://#{host}/favicon1.ico"))

      expect(yielded_favicons[1]).to be_kind_of(Spidr::Page)
      expect(yielded_favicons[1].content_type).to eq('image/vnd.microsoft.icon')
      expect(yielded_favicons[1].url).to eq(URI("http://#{host}/favicon2.ico"))
    end
  end

  describe "#every_html_comment" do
    module TestAgentEveryHTMLComment
      class TestApp < Sinatra::Base

        set :host, 'example.com'
        set :port, 80

        get '/' do
          <<~HTML
          <html>
            <head>
              <!-- comment 1 -->
            </head>
            <!-- -->
            <body>
              <!-- comment 2 -->
            </body>
          </html>
          HTML
        end
      end
    end

    let(:host) { 'example.com' }

    let(:test_app) { TestAgentEveryHTMLComment::TestApp }

    before do
      stub_request(:any, /#{Regexp.escape(host)}/).to_rack(test_app)
    end

    it "must yield every non-empty/non-whitespace HTML comment String" do
      yielded_comments = []

      subject.every_html_comment do |comment|
        yielded_comments << comment
      end

      subject.start_at("http://#{host}/")

      expect(yielded_comments).to match_array(
        [
          'comment 1',
          'comment 2'
        ]
      )
    end
  end

  describe "#every_javascript" do
    module TestAgentEveryJavaScript
      class TestApp < Sinatra::Base

        set :host, 'example.com'
        set :port, 80

        get '/' do
          <<~HTML
          <html>
            <head>
              <script type="text/javascript" src="/javascript1.js"></script>
              <script type="text/javascript">javascript2</script>
            </head>
            <body>
              <a href="/link1">link1</a>
              <a href="http://host2.example.com/offsite-link">offsite link</a>
              <a href="/link2">link2</a>
            </body>
          </html>
          HTML
        end

        get '/javascript1.js' do
          content_type 'text/javascript'
          "javascript1"
        end
      end
    end

    let(:host) { 'example.com' }

    let(:test_app) { TestAgentEveryJavaScript::TestApp }

    before do
      stub_request(:any, /#{Regexp.escape(host)}/).to_rack(test_app)
    end

    it "must yield both the contents of .js files and inline <script> tags" do
      yielded_javascripts = []

      subject.every_javascript do |js|
        yielded_javascripts << js
      end

      subject.start_at("http://#{host}/")

      expect(yielded_javascripts).to match_array(%w[javascript1 javascript2])
    end
  end

  describe "#every_javascript_string" do
    module TestAgentEveryJavaScriptString
      class TestApp < Sinatra::Base

        set :host, 'example.com'
        set :port, 80

        get '/' do
          <<~HTML
          <html>
            <head>
              <script type="text/javascript" src="/javascript1.js"></script>
              <script type="text/javascript">
              var str3 = "string #3";
              var str4 = 'string #4';
              </script>
            </head>
            <body>
              <a href="/link1">link1</a>
              <a href="http://host2.example.com/offsite-link">offsite link</a>
              <a href="/link2">link2</a>
            </body>
          </html>
          HTML
        end

        get '/javascript1.js' do
          content_type 'text/javascript'
          <<~JS
          var str1 = "string #1";
          var str2 = 'string #2';
          JS
        end
      end
    end

    let(:host) { 'example.com' }

    let(:test_app) { TestAgentEveryJavaScriptString::TestApp }

    before do
      stub_request(:any, /#{Regexp.escape(host)}/).to_rack(test_app)
    end

    it "must yield every JavaScript string from any <script> tag" do
      yielded_javascript_strings = []

      subject.every_javascript_string do |string|
        yielded_javascript_strings << string
      end

      subject.start_at("http://#{host}/")

      expect(yielded_javascript_strings).to match_array(
        [
          'string #1',
          'string #2',
          'string #3',
          'string #4'
        ]
      )
    end
  end

  describe "#every_javascript_comment" do
    module TestAgentEveryJavaScriptComment
      class TestApp < Sinatra::Base

        set :host, 'example.com'
        set :port, 80

        get '/' do
          <<~HTML
          <html>
            <head>
              <script type="text/javascript" src="/javascript1.js"></script>
              <script type="text/javascript">
              // comment 3
              var str3 = "string #3";
              /*
                 comment 4
               */
              var str4 = 'string #4';
              </script>
            </head>
            <body>
              <a href="/link1">link1</a>
              <a href="http://host2.example.com/offsite-link">offsite link</a>
              <a href="/link2">link2</a>
            </body>
          </html>
          HTML
        end

        get '/javascript1.js' do
          content_type 'text/javascript'
          <<~JS
          // comment 1
          var str1 = "string #1";
          /* comment 2 */
          var str2 = 'string #2';
          JS
        end
      end
    end

    let(:host) { 'example.com' }

    let(:test_app) { TestAgentEveryJavaScriptComment::TestApp }

    before do
      stub_request(:any, /#{Regexp.escape(host)}/).to_rack(test_app)
    end

    it "must yield every JavaScript comment from any <script> tag" do
      yielded_javascript_comments = []

      subject.every_javascript_comment do |comment|
        yielded_javascript_comments << comment
      end

      subject.start_at("http://#{host}/")

      expect(yielded_javascript_comments).to match_array(
        [
          "// comment 1\n",
          "/* comment 2 */",
          "// comment 3\n",
          "/*\n       comment 4\n     */"
        ]
      )
    end
  end

  describe "#every_comment" do
    module TestAgentEveryComment
      class TestApp < Sinatra::Base

        set :host, 'example.com'
        set :port, 80

        get '/' do
          <<~HTML
          <html>
            <head>
              <!-- HTML comment 1 -->
              <script type="text/javascript" src="/javascript1.js"></script>
              <script type="text/javascript">
              // JavaScript comment 3
              var str3 = "string #3";
              /*
                 JavaScript comment 4
               */
              var str4 = 'string #4';
              </script>
            </head>
            <!-- -->
            <body>
              <!-- HTML comment 2 -->
              <a href="/link1">link1</a>
              <a href="http://host2.example.com/offsite-link">offsite link</a>
              <a href="/link2">link2</a>
            </body>
          </html>
          HTML
        end

        get '/javascript1.js' do
          content_type 'text/javascript'
          <<~JS
          // JavaScript comment 1
          var str1 = "string #1";
          /* JavaScript comment 2 */
          var str2 = 'string #2';
          JS
        end
      end
    end

    let(:host) { 'example.com' }

    let(:test_app) { TestAgentEveryComment::TestApp }

    before do
      stub_request(:any, /#{Regexp.escape(host)}/).to_rack(test_app)
    end

    it "must yield every HTML and JavaScript comment from any <script> tag" do
      yielded_comments = []

      subject.every_comment do |comment|
        yielded_comments << comment
      end

      subject.start_at("http://#{host}/")

      expect(yielded_comments).to match_array(
        [
          "HTML comment 1",
          "// JavaScript comment 1\n",
          "/* JavaScript comment 2 */",
          "// JavaScript comment 3\n",
          "/*\n       JavaScript comment 4\n     */",
          "HTML comment 2"
        ]
      )
    end
  end
end
