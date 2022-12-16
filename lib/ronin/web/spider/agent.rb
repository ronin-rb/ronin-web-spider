#
# ronin-web-spider - A collection of common web spidering routines.
#
# Copyright (c) 2006-2022 Hal Brodigan (postmodern.mod3 at gmail.com)
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

require 'ronin/support/crypto/cert'
require 'ronin/support/text/patterns'
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
        # @param [Spidr::Proxy, Hash, URI::HTTP, String, nil] proxy
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
        def initialize(proxy:      ENV['RONIN_HTTP_PROXY'],
                       user_agent: ENV['RONIN_HTTP_USER_AGENT'],
                       **kwargs,
                       &block)
          super(proxy: proxy, user_agent: user_agent, **kwargs,&block)
        end

        # The visited host names.
        #
        # @return [Set<String>, nil]
        attr_reader :visited_hosts

        #
        # Passes every unique host name that the agent visits to the given
        # block and populates {#hosts}.
        #
        # @yield [host]
        #
        # @yieldparam [String] host
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
        attr_reader :collected_certs

        #
        # Passes every unique TLS certificate to the given block and populates
        # {#certs}.
        #
        # @yield [cert]
        #
        # @yieldparam [Ronin::Support::Crypto::Cert]
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
        # @see https://rubydoc.info/gems/spidr/Spidr/Page
        #
        def every_favicon
          every_page do |page|
            yield page if page.icon?
          end
        end

        #
        # Passes every piece of JavaScript to the given block.
        #
        # @yield [js]
        #   The given block will be passed every piece of JavaScript source.
        #
        # @yieldparam [String] js
        #   The JavaScript source code.
        #
        def every_javascript
          # yield inner text of every `<script type="text/javascript">` tag.
          every_html_page do |page|
            page.xpath('//script[@type="text/javascript"]').each do |script|
              yield script.inner_text
            end
          end

          every_javascript_page do |page|
            yield page.body
          end
        end

        #
        # Passes every JavaScript string value to the given block.
        #
        # @yield [string]
        #   The given block will be passed each JavaScript string with the quote
        #   marks removed.
        #
        # @yieldparam [String] string
        #   The parsed contents of a JavaScript string.
        #
        def every_javascript_string
          every_javascript do |js|
            js.scan(Support::Text::Patterns::STRING) do |js_string|
              yield Support::Encoders::JS.unquote(js_string)
            end
          end
        end

      end
    end
  end
end
