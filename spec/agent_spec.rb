require 'spec_helper'
require 'ronin/web/spider/agent'

require 'webmock/rspec'
require 'sinatra/base'

describe Ronin::Web::Spider::Agent do
  describe "#initialize" do
    context "when Ronin::Support::Network::HTTP.proxy is set" do
      let(:proxy_host) { 'example.com' }
      let(:proxy_port) { 8080 }
      let(:proxy_uri)  { URI::HTTP.build(host: proxy_host, port: proxy_port) }

      before { Ronin::Support::Network::HTTP.proxy = proxy_uri }

      it "must use Ronin::Support::Network::HTTP.proxy and set #proxy" do
        expect(subject.proxy).to be_kind_of(Spidr::Proxy)
        expect(subject.proxy.host).to eq(proxy_host)
        expect(subject.proxy.port).to eq(proxy_port)
      end

      after { Ronin::Support::Network::HTTP.proxy = nil }
    end

    context "when Ronin::Support::Network::HTTP.user_agent is set" do
      let(:user_agent) { 'Foo Bar' }

      before { Ronin::Support::Network::HTTP.user_agent = user_agent }

      it "must use Ronin::Support::Network::HTTP.user_agent and set #user_agent" do
        expect(subject.user_agent).to eq(user_agent)
      end

      after { Ronin::Support::Network::HTTP.user_agent = nil }
    end

    context "when given the proxy: keyword argument" do
      let(:proxy_host) { 'example.com' }
      let(:proxy_port) { 8080 }

      context "and it's an Addressable::URI" do
        let(:proxy) { Addressable::URI.new(host: proxy_host, port: proxy_port) }

        subject { described_class.new(proxy: proxy) }

        it "must convert it to a Spidr::Proxy object" do
          expect(subject.proxy).to be_kind_of(Spidr::Proxy)
          expect(subject.proxy.host).to eq(proxy_host)
          expect(subject.proxy.port).to eq(proxy_port)
        end
      end

      context "and it's an URI::HTTP" do
        let(:proxy) { URI::HTTP.build(host: proxy_host, port: proxy_port) }

        subject { described_class.new(proxy: proxy) }

        it "must convert it to a Spidr::Proxy object" do
          expect(subject.proxy).to be_kind_of(Spidr::Proxy)
          expect(subject.proxy.host).to eq(proxy_host)
          expect(subject.proxy.port).to eq(proxy_port)
        end
      end

      context "and it's a Hash" do
        let(:proxy) do
          {host: proxy_host, port: proxy_port}
        end

        subject { described_class.new(proxy: proxy) }

        it "must convert it to a Spidr::Proxy object" do
          expect(subject.proxy).to be_kind_of(Spidr::Proxy)
          expect(subject.proxy.host).to eq(proxy_host)
          expect(subject.proxy.port).to eq(proxy_port)
        end
      end

      context "and it's a String" do
        let(:proxy) { "http://#{proxy_host}:#{proxy_port}" }

        subject { described_class.new(proxy: proxy) }

        it "must convert it to a Spidr::Proxy object" do
          expect(subject.proxy).to be_kind_of(Spidr::Proxy)
          expect(subject.proxy.host).to eq(proxy_host)
          expect(subject.proxy.port).to eq(proxy_port)
        end
      end
    end

    context "when given the user_agent: keyword argument" do
      context "and it's a String" do
        let(:user_agent) { "test user-agent" }

        subject { described_class.new(user_agent: user_agent) }

        it "must set the #user_agent" do
          expect(subject.user_agent).to eq(user_agent)
        end
      end

      context "and it's a Symbol" do
        let(:user_agent) { :chrome_linux }
        let(:expected_user_agent) do
          Ronin::Support::Network::HTTP::UserAgents[user_agent]
        end

        subject { described_class.new(user_agent: user_agent) }

        it "must map the Symbol to one of Ronin::Support::Network::HTTP::UserAgents" do
          expect(subject.user_agent).to eq(expected_user_agent)
        end
      end
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
    let(:host2) { 'host2.example.com' }

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
      subject.every_host { |host| nil }
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

    context "when the block accepts two arguments" do
      it "must yield every HTML comment and the Spidr::Page object" do
        yielded_comments = []
        yielded_pages    = []

        subject.every_html_comment do |comment,page|
          yielded_comments << comment
          yielded_pages    << page
        end

        subject.start_at("http://#{host}/")

        expect(yielded_comments).to all(be_kind_of(String))
        expect(yielded_pages).to all(be_kind_of(Spidr::Page))
      end
    end

    context "when the page has a text/html Content-Type, but no response body" do
      module TestAgentEveryHTMLComment
        class TestAppWithEmptyResponses < Sinatra::Base

          set :host, 'example.com'
          set :port, 80

          get '/' do
            <<~HTML
              <html>
                <body>
                  <!-- comment 1 -->
                  <a href="/link1">link1</a>
                  <a href="/link2">link2</a>
                </body>
              </html>
            HTML
          end

          get '/link1' do
            halt 200
          end

          get '/link2' do
            <<~HTML
              <html>
                <body>
                  <!-- comment 2 -->
                </body>
              </html>
            HTML
          end
        end
      end

      let(:test_app) { TestAgentEveryHTMLComment::TestAppWithEmptyResponses }

      it "must ignore the page" do
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

    context "when the block accepts two arguments" do
      it "must yield every JavaScript and the Spidr::Page object" do
        yielded_javascripts = []
        yielded_pages       = []

        subject.every_javascript do |javascript,page|
          yielded_javascripts << javascript
          yielded_pages       << page
        end

        subject.start_at("http://#{host}/")

        expect(yielded_javascripts).to all(be_kind_of(String))
        expect(yielded_pages).to all(be_kind_of(Spidr::Page))
      end
    end

    context "when the page has a text/html Content-Type, but no response body" do
      module TestAgentEveryJavaScript
        class TestAppWithEmptyResponses < Sinatra::Base

          set :host, 'example.com'
          set :port, 80

          get '/' do
            <<~HTML
              <html>
                <head>
                  <script type="text/javascript" src="/javascript1.js"></script>
                </head>
                <body>
                  <a href="/link1">link1</a>
                  <a href="/link2">link2</a>
                </body>
              </html>
            HTML
          end

          get '/javascript1.js' do
            content_type 'text/javascript'
            "javascript1"
          end

          get '/link1' do
            halt 200
          end

          get '/link2' do
            <<~HTML
              <html>
                <body>
                  <script type="text/javascript">javascript2</script>
                </body>
              </html>
            HTML
          end
        end
      end

      let(:test_app) { TestAgentEveryJavaScript::TestAppWithEmptyResponses }

      it "must ignore the page" do
        yielded_javascripts = []

        subject.every_javascript do |js|
          yielded_javascripts << js
        end

        subject.start_at("http://#{host}/")

        expect(yielded_javascripts).to match_array(%w[javascript1 javascript2])
      end
    end

    context "when the responses do not include 'charset=utf-8'" do
      module TestAgentEveryJavaScript
        class TestAppWithoutCharset < Sinatra::Base

          set :host, 'example.com'
          set :port, 80

          get '/' do
            content_type 'text/html', charset: 'US-ASCII'
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
            content_type 'text/javascript', charset: 'US-ASCII'
            "javascript1"
          end
        end
      end

      let(:test_app) { TestAgentEveryJavaScript::TestAppWithoutCharset }

      it "must default the encoding of the JavaScript Strings to UTF-8" do
        yielded_javascripts = []

        subject.every_javascript do |js|
          yielded_javascripts << js
        end

        subject.start_at("http://#{host}/")

        expect(yielded_javascripts.map(&:encoding)).to all(be(Encoding::UTF_8))
      end
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

    context "when the block accepts two arguments" do
      it "must yield every JavaScript string and the Spidr::Page object" do
        yielded_javascript_strings = []
        yielded_pages              = []

        subject.every_javascript_string do |string,page|
          yielded_javascript_strings << string
          yielded_pages              << page
        end

        expect(yielded_javascript_strings).to all(be_kind_of(String))
        expect(yielded_pages).to all(be_kind_of(Spidr::Page))
      end
    end

    context "when the JavaScript contains inline regexes" do
      module TestAgentEveryJavaScriptString
        class TestAppWithInlineRegexes < Sinatra::Base

          set :host, 'example.com'
          set :port, 80

          get '/' do
            <<~HTML
              <html>
                <head>
                  <script type="text/javascript" src="/javascript1.js"></script>
                  <script type="text/javascript">
                  var foo  = /abc[`~!@#$%^&\\*\\(\\)_\\+\\-=\\[\\]\\{\\}\\\\\\|;:'",.\\/?<>]xyz/;
                  var str3 = "string #3";
                  var bar  = [/multi
                  line/];
                  var str4 = 'string #4';
                  var baz  = {foo: /[\\{\\}]/};
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
              var foo  = foo(/[\\u200d\\ud800-\\udfff\\u0300-\\u036f\\ufe20-\\ufe2f\\u20d0-\\u20ff\\ufe0e\\ufe0f]/g);
              var str1 = "string #1";
              var bar  = /foo/.test(foo);
              var str2 = 'string #2';
              var baz  = /\\s+\\/\\\\/;
            JS
          end
        end
      end

      let(:test_app) { TestAgentEveryJavaScriptString::TestAppWithInlineRegexes }

      it "must skip past the inline regexes" do
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

    context "when the JavaScript contains template literals" do
      module TestAgentEveryJavaScriptString
        class TestAppWithTemplateLiterals < Sinatra::Base

          set :host, 'example.com'
          set :port, 80

          get '/' do
            <<~HTML
              <html>
                <head>
                  <script type="text/javascript" src="/javascript1.js"></script>
                  <script type="text/javascript">
                  var foo  = `foo`;
                  var str3 = "string #3";
                  var bar  = `bar = ${1+1}`;
                  var str4 = 'string #4';
                  var baz  = `baz ${baz}`;
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
              var foo  = `foo = "${foo}"`;
              var str1 = "string #1";
              var bar  = `bar = '${bar}'`;
              var str2 = 'string #2';
              var baz  = `baz = /${baz}/`;
            JS
          end
        end
      end

      let(:test_app) { TestAgentEveryJavaScriptString::TestAppWithInlineRegexes }

      it "must skip past the template literals" do
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
  end

  describe "#every_javascript_relative_path_string" do
    module TestAgentEveryJavaScriptRelativePathString
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
                var str4 = '../up/directory';
                var str5 = 'file.txt';
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
            var str1 = "/absolute/path";
            var str2 = "sub/directory";
          JS
        end
      end
    end

    let(:host) { 'example.com' }

    let(:test_app) { TestAgentEveryJavaScriptRelativePathString::TestApp }

    before do
      stub_request(:any, /#{Regexp.escape(host)}/).to_rack(test_app)
    end

    it "must yield every JavaScript relative path string from any <script> tag" do
      yielded_javascript_relative_paths = []

      subject.every_javascript_relative_path_string do |path|
        yielded_javascript_relative_paths << path
      end

      subject.start_at("http://#{host}/")

      expect(yielded_javascript_relative_paths).to match_array(
        [
          "sub/directory",
          "../up/directory",
          'file.txt'
        ]
      )
    end

    context "when the block accepts two arguments" do
      it "must yield every JavaScript relative path string and the Spidr::Page object" do
        yielded_javascript_relative_paths = []
        yielded_pages                     = []

        subject.every_javascript_relative_path_string do |path,page|
          yielded_javascript_relative_paths << path
          yielded_pages                     << page
        end

        subject.start_at("http://#{host}/")

        expect(yielded_javascript_relative_paths).to all(be_kind_of(String))
        expect(yielded_pages).to all(be_kind_of(Spidr::Page))
      end
    end
  end

  describe "#every_javascript_absolute_path_string" do
    module TestAgentEveryJavaScriptAbsolutePathString
      class TestApp < Sinatra::Base

        set :host, 'example.com'
        set :port, 80

        get '/' do
          <<~HTML
            <html>
              <head>
                <script type="text/javascript" src="/javascript1.js"></script>
                <script type="text/javascript">
                var str3 = "../relative/path";
                var str4 = '/directory/filename';
                var str5 = 'file.txt';
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
            var str1 = "/filename";
            var str2 = "sub/directory";
          JS
        end
      end
    end

    let(:host) { 'example.com' }

    let(:test_app) { TestAgentEveryJavaScriptAbsolutePathString::TestApp }

    before do
      stub_request(:any, /#{Regexp.escape(host)}/).to_rack(test_app)
    end

    it "must yield every JavaScript absolute path string from any <script> tag" do
      yielded_javascript_absolute_paths = []

      subject.every_javascript_absolute_path_string do |path|
        yielded_javascript_absolute_paths << path
      end

      subject.start_at("http://#{host}/")

      expect(yielded_javascript_absolute_paths).to match_array(
        [
          "/directory/filename",
          '/filename'
        ]
      )
    end

    context "when the block accepts two arguments" do
      it "must yield every JavaScript absolute path string and the Spidr::Page object" do
        yielded_javascript_absolute_paths = []
        yielded_pages                     = []

        subject.every_javascript_absolute_path_string do |path,page|
          yielded_javascript_absolute_paths << path
          yielded_pages                     << page
        end

        subject.start_at("http://#{host}/")

        expect(yielded_javascript_absolute_paths).to all(be_kind_of(String))
        expect(yielded_pages).to all(be_kind_of(Spidr::Page))
      end
    end
  end

  describe "#every_javascript_path_string" do
    module TestAgentEveryJavaScriptPathString
      class TestApp < Sinatra::Base

        set :host, 'example.com'
        set :port, 80

        get '/' do
          <<~HTML
            <html>
              <head>
                <script type="text/javascript" src="/javascript1.js"></script>
                <script type="text/javascript">
                var str3 = "../relative/path";
                var str4 = '/absolute/path';
                var str5 = 'file.txt';
                var str6 = "foo";
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
            var str1 = "/filename";
            var str2 = "sub/directory";
          JS
        end
      end
    end

    let(:host) { 'example.com' }

    let(:test_app) { TestAgentEveryJavaScriptPathString::TestApp }

    before do
      stub_request(:any, /#{Regexp.escape(host)}/).to_rack(test_app)
    end

    it "must yield every JavaScript path string from any <script> tag" do
      yielded_javascript_paths = []

      subject.every_javascript_path_string do |path|
        yielded_javascript_paths << path
      end

      subject.start_at("http://#{host}/")

      expect(yielded_javascript_paths).to match_array(
        [
          "../relative/path",
          "/absolute/path",
          "file.txt",
          '/filename',
          "sub/directory"
        ]
      )
    end

    context "when the block accepts two arguments" do
      it "must yield every JavaScript path string and the Spidr::Page object" do
        yielded_javascript_paths = []
        yielded_pages            = []

        subject.every_javascript_path_string do |path,page|
          yielded_javascript_paths << path
          yielded_pages            << page
        end

        subject.start_at("http://#{host}/")

        expect(yielded_javascript_paths).to all(be_kind_of(String))
        expect(yielded_pages).to all(be_kind_of(Spidr::Page))
      end
    end
  end

  describe "#every_javascript_url_string" do
    module TestAgentEveryJavaScriptURLString
      class TestApp < Sinatra::Base

        set :host, 'example.com'
        set :port, 80

        get '/' do
          <<~HTML
            <html>
              <head>
                <script type="text/javascript" src="/javascript1.js"></script>
                <script type="text/javascript">
                var str4 = "string #3";
                var str5 = 'https://example.com/js_url2';
                var str6 = 'string #5';
                var str7 = "contains a URL: https://example.com/";
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
            var str2 = "http://example.com/js_url1";
            var str3 = "contains a URL: https://example.com/";
          JS
        end
      end
    end

    let(:host) { 'example.com' }

    let(:test_app) { TestAgentEveryJavaScriptURLString::TestApp }

    before do
      stub_request(:any, /#{Regexp.escape(host)}/).to_rack(test_app)
    end

    it "must yield every JavaScript URL string from any <script> tag" do
      yielded_javascript_urls = []

      subject.every_javascript_url_string do |url|
        yielded_javascript_urls << url
      end

      subject.start_at("http://#{host}/")

      expect(yielded_javascript_urls).to match_array(
        [
          "http://example.com/js_url1",
          "https://example.com/js_url2"
        ]
      )
    end

    context "when the block accepts two arguments" do
      it "must yield every JavaScript URL string and the Spidr::Page object" do
        yielded_javascript_urls = []
        yielded_pages           = []

        subject.every_javascript_url_string do |url,page|
          yielded_javascript_urls << url
          yielded_pages           << page
        end

        subject.start_at("http://#{host}/")

        expect(yielded_javascript_urls).to all(be_kind_of(String))
        expect(yielded_pages).to all(be_kind_of(Spidr::Page))
      end
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

    context "when the block accepts two arguments" do
      it "must yield every JavaScript comment and the Spidr::Page object" do
        yielded_javascript_comments = []
        yielded_pages               = []

        subject.every_javascript_comment do |comment,page|
          yielded_javascript_comments << comment
          yielded_pages               << page
        end

        subject.start_at("http://#{host}/")

        expect(yielded_javascript_comments).to all(be_kind_of(String))
        expect(yielded_pages).to all(be_kind_of(Spidr::Page))
      end
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

    context "when the block accepts two arguments" do
      it "must yield every HTML or JavaScript and the Spidr::Page object" do
        yielded_comments = []
        yielded_pages    = []

        subject.every_comment do |comment,page|
          yielded_comments << comment
          yielded_pages    << page
        end

        subject.start_at("http://#{host}/")

        expect(yielded_comments).to all(be_kind_of(String))
        expect(yielded_pages).to all(be_kind_of(Spidr::Page))
      end
    end
  end
end
