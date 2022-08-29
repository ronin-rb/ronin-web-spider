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

      end
    end
  end
end
