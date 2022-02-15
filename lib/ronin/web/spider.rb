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

require 'set'

module Ronin
  module Web
    module Spider
      #
      # Creates a new agent and begin spidering at the given URL.
      #
      # @param [URI::HTTP, String] url
      #   The URL to start spidering at.
      #
      # @param [Hash{Symbol => Object}] kwargs
      #   Additional keyword arguments for `Spidr.start_at`.
      #
      # @yield [agent]
      #   If a block is given, it will be passed the newly created agent
      #   before it begins spidering.
      #
      # @yieldparam [Agent] agent
      #   The newly created agent.
      #
      # @return [Agent]
      #   The web spider agent, after it has completed spidering.
      #
      # @see https://rubydoc.info/gems/spidr/Spidr/Agent#start_at-class_method
      #
      def self.start_at(url,**kwargs,&block)
        Agent.start_at(url,**kwargs,&block)
      end

      #
      # Creates a new agent and spiders the given host.
      #
      # @param [String] name
      #   The host-name to spider.
      #
      # @param [Hash{Symbol => Object}] kwargs
      #   Additional keyword arguments for `Spidr.host`.
      #
      # @yield [agent]
      #   If a block is given, it will be passed the newly created agent
      #   before it begins spidering.
      #
      # @yieldparam [Agent] agent
      #   The newly created agent.
      #
      # @return [Agent]
      #   The web spider agent, after it has completed spidering.
      #
      # @see https://rubydoc.info/gems/spidr/Spidr/Agent#host-class_method
      #
      def self.host(name,**kwargs,&block)
        Agent.host(name,**kwargs,&block)
      end

      #
      # Creates a new agent and spiders the web-site located at the given URL.
      #
      # @param [URI::HTTP, String] url
      #   The web-site to spider.
      #
      # @param [Hash{Symbol => Object}] kwargs
      #   Additional keyword arguments for `Spidr.site`.
      #
      # @yield [agent]
      #   If a block is given, it will be passed the newly created agent
      #   before it begins spidering.
      #
      # @yieldparam [Agent] agent
      #   The newly created agent.
      #
      # @return [Agent]
      #   The web spider agent, after it has completed spidering.
      #
      # @see https://rubydoc.info/gems/spidr/Spidr/Agent#site-class_method
      #
      def self.site(url,**kwargs,&block)
        Agent.site(url,**kwargs,&block)
      end

      #
      # Creates a new agent and spiders the entire domain.
      #
      # @param [String] name
      #   The top-level domain to spider.
      #
      # @param [Hash{Symbol => Object}] kwargs
      #   Additional keyword arguments for `Spidr.domain`.
      #
      # @yield [agent]
      #   If a block is given, it will be passed the newly created agent
      #   before it begins spidering.
      #
      # @yieldparam [Agent] agent
      #   The newly created agent.
      #
      # @return [Agent]
      #   The web spider agent, after it has completed spidering.
      #
      # @see https://rubydoc.info/gems/spidr/Spidr/Agent#domain-class_method
      #
      def self.domain(name,**kwargs,&block)
        Agent.domain(name,**kwargs,&block)
      end

      #
      # Spiders a host, a domain, or a website.
      #
      # @param [String] host
      #   The specific hostname to spider.
      #
      # @param [String] domain
      #   The domain name to spider.
      #
      # @param [String] site
      #   The website to spider.
      #
      # @param [Hash{Symbol => Object}] kwargs
      #   Additional keyword arguments for `Spidr.host`, `Spidr.domain`,
      #   `Spidr.site`.
      #
      # @return [Agent]
      #   The web spider agent, after it has completed spidering.
      #
      # @raise [ArgumentError]
      #   Must specify the `host:`, `domain:`, or `site:` keyword argument.
      #
      # @example
      #   Spider.spider(host: 'example.com')
      #
      # @example
      #   Spider.spider(domain: 'example.com')
      #
      # @example
      #   Spider.spider(site: 'https://example.com/')
      #
      # @see host
      # @see domain
      # @see site
      #
      def self.spider(host: nil, domain: nil, site: nil, **kwargs, &block)
        if    host   then host(host,**kwargs,&block)
        elsif domain then domain(domain,**kwargs,&block)
        elsif site   then site(site,**kwargs,&block)
        else
          raise(ArgumentError,"must specify host:, domain:, or site: argument")
        end
      end

      #
      # Spiders a website and passes every URL to the given block.
      #
      # @param [Hash{Symbol => Object}] kwargs
      #   Additional keyword arguments for {spider}.
      #
      # @option kwargs [String] :host
      #   The specific hostname to spider.
      #
      # @option kwargs [String] :domain
      #   The domain name to spider.
      #
      # @option kwargs [URL::HTTP, String] :site
      #   The website to spider.
      #
      # @yield [url]
      #   The given block will be passed every URL that will be spidered.
      #
      # @yieldparam [URI::HTTP] url
      #   A URL that will be spidered.
      #
      # @raise [ArgumentError]
      #   At least one of the `host:`, `domain:`, or `site:` keyword arguments
      #   must be given.
      #
      # @example Spider a host and find every URL:
      #   Spider.every_url(host: 'www.example.com') do |url|
      #     puts url
      #   end
      #
      # @example Spider a domain and find every URL:
      #   Spider.every_url(domain: 'example.com') do |url|
      #     puts url
      #   end
      #
      # @example Spider a website and find every URL:
      #   Spider.every_url(site: 'https://example.com/') do |url|
      #     puts url
      #   end
      #
      def self.every_url(**kwargs,&block)
        spider(**kwargs) do |agent|
          agent.every_url(&block)
        end
      end

      #
      # Spiders a website and passes every URL that matches the pattern to the
      # given block.
      #
      # @param [String, Regexp] pattern
      #   The pattern to match URLs against.
      #
      # @param [Hash{Symbol => Object}] kwargs
      #   Additional keyword arguments for {spider}.
      #
      # @option kwargs [String] :host
      #   The specific hostname to spider.
      #
      # @option kwargs [String] :domain
      #   The domain name to spider.
      #
      # @option kwargs [URL::HTTP, String] :site
      #   The website to spider.
      #
      # @yield [url]
      #   The given block will be passed every matching URL that will be
      #   spidered.
      #
      # @yieldparam [URI::HTTP] url
      #   A URL that will be spidered.
      #
      # @raise [ArgumentError]
      #   At least one of the `host:`, `domain:`, or `site:` keyword arguments
      #   must be given.
      #
      # @example Spider a host and find URL ending in `.php`:
      #   Spider.every_url_like(/\.php$/, host: 'www.example.com') do |url|
      #     puts url
      #   end
      #
      # @example Spider a domain and find URL ending in `.php`:
      #   Spider.every_url_like(/\.php$/, domain: 'example.com') do |url|
      #     puts url
      #   end
      #
      # @example Spider a website and find URL ending in `.php`:
      #   Spider.every_url_like(/\.php$/, site: 'https://example.com/') do |url|
      #     puts url
      #   end
      #
      def self.every_url_like(pattern,**kwargs,&block)
        spider(**kwargs) do |agent|
          agent.every_url_like(pattern,&block)
        end
      end

      #
      # Spiders a website and passes every page to the given block.
      #
      # @param [Hash{Symbol => Object}] kwargs
      #   Additional keyword arguments for {spider}.
      #
      # @option kwargs [String] :host
      #   The specific hostname to spider.
      #
      # @option kwargs [String] :domain
      #   The domain name to spider.
      #
      # @option kwargs [URL::HTTP, String] :site
      #   The website to spider.
      #
      # @yield [page]
      #   the given block will be passed every page that is visited.
      #
      # @yieldparam [Spidr::Page] page
      #   A page that has been visited.
      #
      # @raise [ArgumentError]
      #   At least one of the `host:`, `domain:`, or `site:` keyword arguments
      #   must be given.
      #
      # @example Spider a host:
      #   Spider.every_page(host: 'www.example.com') do |page|
      #     puts page.url
      #   end
      #
      # @example Spider a domain:
      #   Spider.every_page(domain: 'example.com') do |page|
      #     puts page.url
      #   end
      #
      # @example Spider a website:
      #   Spider.every_page(site: 'https://example.com/') do |page|
      #     puts pageurl
      #   end
      #
      def self.every_page(**kwargs,&block)
        spider(**kwargs) do |agent|
          agent.every_page(&block)
        end
      end

      #
      # Spiders a website and returns the list of visited URLs.
      #
      # @param [Regexp, String, nil] like
      #   The optional pattern to filter URLs by.
      #
      # @param [Hash{Symbol => Object}] kwargs
      #   Additional keyword arguments for {spider}.
      #
      # @option kwargs [String] :host
      #   The specific hostname to spider.
      #
      # @option kwargs [String] :domain
      #   The domain name to spider.
      #
      # @option kwargs [URL::HTTP, String] :site
      #   The website to spider.
      #
      # @yield [url]
      #   If a block is given, it will be passed every URL that will be
      #   spidered.
      #
      # @yieldparam [URI::HTTP] url
      #   A URL that will be spidered.
      #
      # @return [Set<URI::HTTP>]
      #   The list of URLs that were visited.
      #
      # @raise [ArgumentError]
      #   At least one of the `host:`, `domain:`, or `site:` keyword arguments
      #   must be given.
      #
      # @example
      #   Spider.urls(host: 'www.example.com')
      #   # => [<URI::HTTP http://www.example.com/>, ...]
      #
      # @example
      #   Spider.urls(domain: 'example.com')
      #   # => [<URI::HTTP http://example.com/>, ...]
      #
      # @example
      #   Spider.urls(site: 'https://example.com')
      #   # => [<URI::HTTPS https://example.com/>, ...]
      #
      # @example filter the URLs with a pattern:
      #   Spider.urls(host: 'www.example.com', like: /\.php$/)
      #
      # @example with a block:
      #   Spider.urls(host: 'www.example.com') do |url|
      #     puts url
      #   end
      #   # http://example.com/
      #   # ...
      #
      def self.urls(like: nil, **kwargs)
        urls = Set.new

        spider(**kwargs) do |agent|
          if like
            agent.every_url_like(like) do |url|
              yield url if block_given?
              urls << url
            end
          else
            agent.every_url do |url|
              yield url if block_given?
              urls << url
            end
          end
        end

        return urls
      end
    end
  end
end
