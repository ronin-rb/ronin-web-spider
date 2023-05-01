# frozen_string_literal: true
#
# ronin-web-spider - A collection of common web spidering routines.
#
# Copyright (c) 2006-2023 Hal Brodigan (postmodern.mod3 at gmail.com)
#
# ronin-web-spider is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# ronin-web-spider is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with ronin-web-spider.  If not, see <https://www.gnu.org/licenses/>.
#

require 'spidr/agent'

require 'ronin/support/network/http'
require 'ronin/support/crypto/cert'
require 'ronin/support/text/patterns/source_code'
require 'ronin/support/text/patterns/network'
require 'ronin/support/encoding/js'

module Ronin
  module Web
    module Spider
      #
      # Extends [Spidr::Agent](https://rubydoc.info/gems/spidr/Agent).
      #
      class Agent < Spidr::Agent

        #
        # Creates a new Spider object.
        #
        # @param [Spidr::Proxy, Addressable::URI, URI::HTTP, Hash, String, nil] proxy
        #   The proxy to use while spidering.
        #
        # @param [String, nil] user_agent
        #   The User-Agent string to send.
        #
        # @param [Hash{Symbol => Object}] kwargs
        #   Additional keyword arguments for `Spidr::Agent#initialize`.
        #
        # @option kwargs [String, nil] :referer
        #   The referer URL to send.
        #
        # @option kwargs [Integer] :delay (0)
        #   Duration in seconds to pause between spidering each link.
        #
        # @option kwargs [Array] :schemes (['http', 'https'])
        #   The list of acceptable URI schemes to visit.
        #   The `https` scheme will be ignored if `net/https` cannot be
        #   loaded.
        #
        # @option kwargs [String, nil] :host
        #   The host-name to visit.
        #
        # @option kwargs [Array<String, Regexp, Proc>] :hosts
        #   The patterns which match the host-names to visit.
        #
        # @option kwargs [Array<String, Regexp, Proc>] :ignore_hosts
        #   The patterns which match the host-names to not visit.
        #
        # @option kwargs [Array<Integer, Regexp, Proc>] :ports
        #   The patterns which match the ports to visit.
        #
        # @option kwargs [Array<Integer, Regexp, Proc>] :ignore_ports
        #   The patterns which match the ports to not visit.
        #
        # @option kwargs [Array<String, Regexp, Proc>] :links
        #   The patterns which match the links to visit.
        #
        # @option kwargs [Array<String, Regexp, Proc>] :ignore_links
        #   The patterns which match the links to not visit.
        #
        # @option kwargs [Array<String, Regexp, Proc>] :exts
        #   The patterns which match the URI path extensions to visit.
        #
        # @option kwargs [Array<String, Regexp, Proc>] :ignore_exts
        #   The patterns which match the URI path extensions to not visit.
        #
        # @yield [agent]
        #   If a block is given, it will be passed the newly created web spider
        #   agent.
        #
        # @yieldparam [Agent] agent
        #   The newly created web spider agent.
        #
        # @see https://rubydoc.info/gems/spidr/Spidr/Agent#initialize-instance_method
        #
        # @api public
        #
        def initialize(proxy:      Support::Network::HTTP.proxy,
                       user_agent: Support::Network::HTTP.user_agent,
                       **kwargs,
                       &block)
          proxy = case proxy
                  when Addressable::URI
                    Spidr::Proxy.new(
                      host:     proxy.host,
                      port:     proxy.port,
                      user:     proxy.user,
                      password: proxy.password
                    )
                  else
                    proxy
                  end

          user_agent = case user_agent
                       when Symbol
                         Support::Network::HTTP::UserAgents[user_agent]
                       else
                         user_agent
                       end

          super(proxy: proxy, user_agent: user_agent, **kwargs,&block)
        end

        # The visited host names.
        #
        # @return [Set<String>, nil]
        #
        # @api public
        attr_reader :visited_hosts

        #
        # Passes every unique host name that the agent visits to the given
        # block and populates {#visited_hosts}.
        #
        # @yield [host]
        #
        # @yieldparam [String] host
        #
        # @example
        #   spider.every_host do |host|
        #     puts "Spidring #{host} ..."
        #   end
        #
        # @api public
        #
        def every_host
          @visited_hosts ||= Set.new

          every_page do |page|
            host = page.url.host

            if @visited_hosts.add?(host)
              yield host
            end
          end
        end

        # All certificates encountered while spidering.
        #
        # @return [Array<Ronin::Support::Crypto::Cert>]
        #
        # @api public
        attr_reader :collected_certs

        #
        # Passes every unique TLS certificate to the given block and populates
        # {#collected_certs}.
        #
        # @yield [cert]
        #
        # @yieldparam [Ronin::Support::Crypto::Cert]
        #
        # @example
        #   spider.every_cert do |cert|
        #     puts "Discovered new cert for #{cert.subject.command_name}, #{cert.subject_alt_name}"
        #   end
        #
        # @api public
        #
        def every_cert
          @collected_certs ||= []

          serials = Set.new

          every_page do |page|
            if page.url.scheme == 'https'
              cert = sessions[page.url].peer_cert

              if serials.add?(cert.serial)
                cert = Support::Crypto::Cert(cert)

                @collected_certs << cert
                yield cert
              end
            end
          end
        end

        #
        # Pass every favicon from every page to the given block.
        #
        # @yield [favicon]
        #   The given block will be passed every encountered `.ico` file.
        #
        # @yieldparam [Spidr::Page] favicon
        #   An encountered `.ico` file.
        #
        # @example
        #   spider.every_favicon do |page|
        #     # ...
        #   end
        #
        # @see https://rubydoc.info/gems/spidr/Spidr/Page
        #
        # @api public
        #
        def every_favicon
          every_page do |page|
            yield page if page.icon?
          end
        end

        #
        # Passes every non-empty HTML comment to the given block.
        #
        # @yield [comment]
        #   The given block will be pass every HTML comment.
        #
        # @yield [comment, page]
        #   If the block accepts two arguments, the HTML comment and the page
        #   that the comment was found on will be passed to the given block.
        #
        # @yieldparam [String] comment
        #   The HTML comment inner text, with leading and trailing whitespace
        #   stripped.
        #
        # @yieldparam [Spidr::Page] page
        #   The page that the HTML comment exists on.
        #
        # @example
        #   spider.every_html_comment do |comment|
        #     puts comment
        #   end
        #
        # @api public
        #
        def every_html_comment(&block)
          every_html_page do |page|
            next unless page.doc

            page.doc.xpath('//comment()').each do |comment|
              comment_text = comment.inner_text.strip

              unless comment_text.empty?
                if block.arity == 2
                  yield comment_text, page
                else
                  yield comment_text
                end
              end
            end
          end
        end

        #
        # Passes every piece of JavaScript to the given block.
        #
        # @yield [js]
        #   The given block will be passed every piece of JavaScript source.
        #
        # @yield [js, page]
        #   If the block accepts two arguments, the JavaScript source and the
        #   page that the JavaScript source was found on will be passed to the
        #   given block.
        #
        # @yieldparam [String] js
        #   The JavaScript source code.
        #
        # @yieldparam [Spidr::Page] page
        #   The page that the JavaScript source was found in or on.
        #
        # @example
        #   spider.every_javascript do |js|
        #     puts js
        #   end
        #
        # @api public
        #
        def every_javascript(&block)
          # yield inner text of every `<script type="text/javascript">` tag
          # and every `.js` URL.
          every_html_page do |page|
            next unless page.doc

            page.doc.xpath('//script[@type="text/javascript"]').each do |script|
              source = script.inner_text
              source.force_encoding(Encoding::UTF_8)

              unless source.empty?
                if block.arity == 2
                  yield source, page
                else
                  yield source
                end
              end
            end
          end

          every_javascript_page do |page|
            source = page.body
            source.force_encoding(Encoding::UTF_8)

            if block.arity == 2
              yield source, page
            else
              yield source
            end
          end
        end

        alias every_js every_javascript

        # Regex to match and skip JavaScript inline regexes.
        #
        # @api private
        #
        # @since 0.1.1
        JAVASCRIPT_INLINE_REGEX = %r{
          (?# match before the regex to avoid matching division operators )
          (?:[\{\[\(;:,]\s*|=\s*)
          /
            (?# inline regex contents )
            (?:
              \[ (?:\\. | [^\]]) \] (?# [...] ) |
              \\.                   (?# backslash escaped characters ) |
              [^/]                  (?# everything else )
            )+
          /[dgimsuvy]* (?# also match any regex flags )
        }mx

        # Regex to match and skip JavaScript template literals.
        #
        # @note
        #   This regex will not properly match nested template literals:
        #
        #   ```javascript
        #   `foo ${`bar ${1+1}`}`
        #   ```
        #
        # @api private
        #
        # @since 0.1.1
        JAVASCRIPT_TEMPLATE_LITERAL = /`(?:\\`|[^`])+`/m

        #
        # Passes every JavaScript string value to the given block.
        #
        # @yield [string]
        #   The given block will be passed each JavaScript string with the quote
        #   marks removed.
        #
        # @yield [string, page]
        #   If the block accepts two arguments, the JavaScript string and the
        #   page that the JavaScript string was found on will be passed to the
        #   given block.
        #
        # @yieldparam [String] string
        #   The parsed contents of a JavaScript string.
        #
        # @yieldparam [Spidr::Page] page
        #   The page that the JavaScript string was found in or on.
        #
        # @example
        #   spider.every_javascript_string do |str|
        #     puts str
        #   end
        #
        # @api public
        #
        def every_javascript_string(&block)
          every_javascript do |js,page|
            scanner = StringScanner.new(js)

            until scanner.eos?
              # NOTE: this is a naive JavaScript string scanner and should
              # eventually be replaced with a real JavaScript lexer or parser.
              case scanner.peek(1)
              when '"', "'" # beginning of a quoted string
                js_string = scanner.scan(Support::Text::Patterns::STRING)
                string    = Support::Encoding::JS.unquote(js_string)

                if block.arity == 2
                  yield string, page
                else
                  yield string
                end
              else
                scanner.skip(JAVASCRIPT_INLINE_REGEX) ||
                  scanner.skip(JAVASCRIPT_TEMPLATE_LITERAL) ||
                  scanner.getch
              end
            end
          end
        end

        alias every_js_string every_javascript_string

        # Regular expression that matches relative paths within JavaScript.
        #
        # @note
        #   This matches `foo/bar`, `foo/bar.ext`, `../foo`, and `foo.ext`,
        #   but *not* `/foo`, `foo`, or `foo.`.
        #
        # @api private
        #
        # @since 0.2.0
        JAVASCRIPT_RELATIVE_PATH = %r{
          \A
            (?:
               [^/\\.]+\.[a-z0-9]+ (?# filename.ext)
               |
               [^/\\]+(?:/[^/\\]+)+ (?# dir/filename or dir/filename.ext)
            )
          \z
        }x

        #
        # Passes every JavaScript relative path string to the given block.
        #
        # @yield [string]
        #   The given block will be passed each JavaScript relative path string
        #   with the quote marks removed.
        #
        # @yield [string, page]
        #   If the block accepts two arguments, the JavaScript relative path
        #   string and the page that the JavaScript relative path string was
        #   found on will be passed to the given block.
        #
        # @yieldparam [String] string
        #   The parsed contents of a literal JavaScript relative path string.
        #
        # @yieldparam [Spidr::Page] page
        #   The page that the JavaScript relative path string was found in or
        #   on.
        #
        # @example
        #   spider.every_javascript_relative_path_string do |relative_path|
        #     puts relative_path
        #   end
        #
        # @api public
        #
        # @since 0.2.0
        #
        def every_javascript_relative_path_string(&block)
          every_javascript_string do |string,page|
            if string =~ JAVASCRIPT_RELATIVE_PATH
              if block.arity == 2
                yield string, page
              else
                yield string
              end
            end
          end
        end

        alias every_js_relative_path_string every_javascript_relative_path_string

        # Regular expression that matches absolute paths within JavaScript.
        #
        # @api private
        #
        # @since 0.2.0
        JAVASCRIPT_ABSOLUTE_PATH = %r{\A(?:/[^/\\]+)+\z}

        #
        # Passes every JavaScript absolute path string to the given block.
        #
        # @yield [string]
        #   The given block will be passed each JavaScript absolute path string
        #   with the quote marks removed.
        #
        # @yield [string, page]
        #   If the block accepts two arguments, the JavaScript absolute path
        #   string and the page that the JavaScript absolute path string was
        #   found on will be passed to the given block.
        #
        # @yieldparam [String] string
        #   The parsed contents of a literal JavaScript absolute path string.
        #
        # @yieldparam [Spidr::Page] page
        #   The page that the JavaScript absolute path string was found in or
        #   on.
        #
        # @example
        #   spider.every_javascript_absolute_path_string do |absolute_path|
        #     puts absolute_path
        #   end
        #
        # @api public
        #
        # @since 0.2.0
        #
        def every_javascript_absolute_path_string(&block)
          every_javascript_string do |string,page|
            if string =~ JAVASCRIPT_ABSOLUTE_PATH
              if block.arity == 2
                yield string, page
              else
                yield string
              end
            end
          end
        end

        alias every_js_absolute_path_string every_javascript_absolute_path_string

        #
        # Passes every JavaScript path string to the given block.
        #
        # @yield [string]
        #   The given block will be passed each JavaScript path string with the
        #   quote marks removed.
        #
        # @yield [string, page]
        #   If the block accepts two arguments, the JavaScript path string and
        #   the page that the JavaScript path string was found on will be
        #   passed to the given block.
        #
        # @yieldparam [String] string
        #   The parsed contents of a literal JavaScript path string.
        #
        # @yieldparam [Spidr::Page] page
        #   The page that the JavaScript path string was found in or on.
        #
        # @example
        #   spider.every_javascript_path_string do |path|
        #     puts path
        #   end
        #
        # @api public
        #
        # @since 0.2.0
        #
        def every_javascript_path_string(&block)
          every_javascript_relative_path_string(&block)
          every_javascript_absolute_path_string(&block)
        end

        alias every_js_path_string every_javascript_path_string

        #
        # Passes every JavaScript URL string to the given block.
        #
        # @yield [string]
        #   The given block will be passed each JavaScript URL string with the
        #   quote marks removed.
        #
        # @yield [string, page]
        #   If the block accepts two arguments, the JavaScript URL string and
        #   the page that the JavaScript URL string was found on will be passed
        #   to the given block.
        #
        # @yieldparam [String] string
        #   The parsed contents of a literal JavaScript URL string.
        #
        # @yieldparam [Spidr::Page] page
        #   The page that the JavaScript URL string was found in or on.
        #
        # @example
        #   spider.every_javascript_url_string do |url|
        #     puts url
        #   end
        #
        # @api public
        #
        # @since 0.2.0
        #
        def every_javascript_url_string(&block)
          every_javascript_string do |string,page|
            if string =~ Support::Text::Patterns::URL
              if block.arity == 2
                yield string, page
              else
                yield string
              end
            end
          end
        end

        alias every_js_url_string every_javascript_url_string

        #
        # Passes every JavaScript comment to the given block.
        #
        # @yield [comment]
        #   The given block will be passed each JavaScript comment.
        #
        # @yield [comment, page]
        #   If the block accepts two arguments, the JavaScript comment and the
        #   page that the JavaScript comment was found on will be passed to the
        #   given block.
        #
        # @yieldparam [String] comment
        #   The contents of a JavaScript comment.
        #
        # @yieldparam [Spidr::Page] page
        #   The page that the JavaScript comment was found in or on.
        #
        # @example
        #   spider.every_javascript_comment do |comment|
        #     puts comment
        #   end
        #
        # @api public
        #
        def every_javascript_comment(&block)
          every_javascript do |js,page|
            js.scan(Support::Text::Patterns::JAVASCRIPT_COMMENT) do |comment|
              if block.arity == 2
                yield comment, page
              else
                yield comment
              end
            end
          end
        end

        alias every_js_comment every_javascript_comment

        #
        # Passes every HTML and JavaScript comment to the given block.
        #
        # @yield [comment]
        #   The given block will be passed each HTML or JavaScript comment.
        #
        # @yield [comment, page]
        #   If the block accepts two arguments, the HTML or JavaScript comment
        #   and the page that the HTML/JavaScript comment was found on will be
        #   passed to the given block.
        #
        # @yieldparam [String] comment
        #   The contents of a HTML or JavaScript comment.
        #
        # @yieldparam [Spidr::Page] page
        #   The page that the HTML or JavaScript comment was found in or on.
        #
        # @example
        #   spider.every_comment do |comment|
        #     puts comment
        #   end
        #
        # @see #every_html_comment
        # @see #every_javascript_comment
        #
        # @api public
        #
        def every_comment(&block)
          every_html_comment(&block)
          every_javascript_comment(&block)
        end

      end
    end
  end
end
