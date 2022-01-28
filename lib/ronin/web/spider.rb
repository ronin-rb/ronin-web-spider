#
# ronin-web-spider - A collection of common web spidering routines.
#
# Copyright (c) 2006-2022 Hal Brodigan (postmodern.mod3 at gmail.com)
#
# This file is part of ronin-web-spider.
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

require 'ronin/web/spider/agent'
require 'ronin/web/spider/version'

module Ronin
  module Web
    module Spider
      #
      # Creates a new agent and begin spidering at the given URL.
      #
      # @param [URI::HTTP, String] url
      #   The URL to start spidering at.
      #
      # @param [Hash] options
      #   Additional options. See {Agent#initialize}.
      #
      # @yield [agent]
      #   If a block is given, it will be passed the newly created agent
      #   before it begins spidering.
      #
      # @yieldparam [Agent] agent
      #   The newly created agent.
      #
      # @see https://rubydoc.info/gems/spidr/Spidr/Agent#start_at-class_method
      #
      def self.start_at(url,options={},&block)
        Agent.start_at(url,options,&block)
      end

      #
      # Creates a new agent and spiders the given host.
      #
      # @param [String] name
      #   The host-name to spider.
      #
      # @param [Hash] options
      #   Additional options. See {Agent#initialize}.
      #
      # @yield [agent]
      #   If a block is given, it will be passed the newly created agent
      #   before it begins spidering.
      #
      # @yieldparam [Agent] agent
      #   The newly created agent.
      #
      # @see https://rubydoc.info/gems/spidr/Spidr/Agent#host-class_method
      #
      def self.host(name,options={},&block)
        Agent.host(name,options,&block)
      end

      #
      # Creates a new agent and spiders the web-site located at the given URL.
      #
      # @param [URI::HTTP, String] url
      #   The web-site to spider.
      #
      # @param [Hash] options
      #   Additional options. See {Agent#initialize}.
      #
      # @yield [agent]
      #   If a block is given, it will be passed the newly created agent
      #   before it begins spidering.
      #
      # @yieldparam [Agent] agent
      #   The newly created agent.
      #
      # @see https://rubydoc.info/gems/spidr/Spidr/Agent#site-class_method
      #
      def self.site(url,options={},&block)
        Agent.site(url,options,&block)
      end

      #
      # Creates a new agent and spiders the entire domain.
      #
      # @param [String] name
      #   The top-level domain to spider.
      #
      # @param [Hash] options
      #   Additional options.
      #
      # @yield [agent]
      #   If a block is given, it will be passed the newly created agent
      #   before it begins spidering.
      #
      # @yieldparam [Agent] agent
      #   The newly created agent.
      #
      # @see https://rubydoc.info/gems/spidr/Spidr/Agent#domain-class_method
      #
      def self.domain(name,options={},&block)
        Agent.domain(name,options,&block)
      end
    end
  end
end
