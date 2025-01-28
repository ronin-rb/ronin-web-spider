# frozen_string_literal: true
#
# ronin-web-spider - A collection of common web spidering routines.
#
# Copyright (c) 2006-2025 Hal Brodigan (postmodern.mod3 at gmail.com)
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

require_relative 'spider/agent'
require_relative 'spider/version'

module Ronin
  module Web
    #
    # A collection of common web spidering routines using the [spidr] gem.
    #
    # [spidr]: https://github.com/postmodern/spidr#readme
    #
    # ## Examples
    #
    # Spider a host:
    #
    # ```ruby
    # require 'ronin/web/spider'
    #
    # Ronin::Web::Spider.start_at('http://tenderlovemaking.com/') do |agent|
    #   # ...
    # end
    # ```
    #
    # Spider a host:
    #
    # ```ruby
    # Ronin::Web::Spider.host('solnic.eu') do |agent|
    #   # ...
    # end
    # ```
    #
    # Spider a domain (and any sub-domains):
    #
    # ```ruby
    # Ronin::Web::Spider.domain('ruby-lang.org') do |agent|
    #   # ...
    # end
    # ```
    #
    # Spider a site:
    #
    # ```ruby
    # Ronin::Web::Spider.site('http://www.rubyflow.com/') do |agent|
    #   # ...
    # end
    # ```
    #
    # Spider multiple hosts:
    #
    # ```ruby
    # Ronin::Web::Spider.start_at('http://company.com/', hosts: ['company.com', /host[\d]+\.company\.com/]) do |agent|
    #   # ...
    # end
    # ```
    #
    # Do not spider certain links:
    #
    # ```ruby
    # Ronin::Web::Spider.site('http://company.com/', ignore_links: [%{^/blog/}]) do |agent|
    #   # ...
    # end
    # ```
    #
    # Do not spider links on certain ports:
    #
    # ```ruby
    # Ronin::Web::Spider.site('http://company.com/', ignore_ports: [8000, 8010, 8080]) do |agent|
    #   # ...
    # end
    # ```
    #
    # Do not spider links blacklisted in robots.txt:
    #
    # ```ruby
    # Ronin::Web::Spider.site('http://company.com/', robots: true) do |agent|
    #   # ...
    # end
    # ```
    #
    # Print out visited URLs:
    #
    # ```ruby
    # Ronin::Web::Spider.site('http://www.rubyinside.com/') do |spider|
    #   spider.every_url { |url| puts url }
    # end
    # ```
    #
    # Build a URL map of a site:
    #
    # ```ruby
    # url_map = Hash.new { |hash,key| hash[key] = [] }
    #
    # Ronin::Web::Spider.site('http://intranet.com/') do |spider|
    #   spider.every_link do |origin,dest|
    #     url_map[dest] << origin
    #   end
    # end
    # ```
    #
    # Print out the URLs that could not be requested:
    #
    # ```ruby
    # Ronin::Web::Spider.site('http://company.com/') do |spider|
    #   spider.every_failed_url { |url| puts url }
    # end
    # ```
    #
    # Finds all pages which have broken links:
    #
    # ```ruby
    # url_map = Hash.new { |hash,key| hash[key] = [] }
    #
    # spider = Ronin::Web::Spider.site('http://intranet.com/') do |spider|
    #   spider.every_link do |origin,dest|
    #     url_map[dest] << origin
    #   end
    # end
    #
    # spider.failures.each do |url|
    #   puts "Broken link #{url} found in:"
    #
    #   url_map[url].each { |page| puts "  #{page}" }
    # end
    # ```
    #
    # Search HTML and XML pages:
    #
    # ```ruby
    # Ronin::Web::Spider.site('http://company.com/') do |spider|
    #   spider.every_page do |page|
    #     puts ">>> #{page.url}"
    #
    #     page.search('//meta').each do |meta|
    #       name = (meta.attributes['name'] || meta.attributes['http-equiv'])
    #       value = meta.attributes['content']
    #
    #       puts "  #{name} = #{value}"
    #     end
    #   end
    # end
    # ```
    #
    # Print out the titles from every page:
    #
    # ```ruby
    # Ronin::Web::Spider.site('https://www.ruby-lang.org/') do |spider|
    #   spider.every_html_page do |page|
    #     puts page.title
    #   end
    # end
    # ```
    #
    # Print out every HTTP redirect:
    #
    # ```ruby
    # Ronin::Web::Spider.host('company.com') do |spider|
    #   spider.every_redirect_page do |page|
    #     puts "#{page.url} -> #{page.headers['Location']}"
    #   end
    # end
    # ```
    #
    # Find what kinds of web servers a host is using, by accessing the headers:
    #
    # ```ruby
    # servers = Set[]
    #
    # Ronin::Web::Spider.host('company.com') do |spider|
    #   spider.all_headers do |headers|
    #     servers << headers['server']
    #   end
    # end
    # ```
    #
    # Pause the spider on a forbidden page:
    #
    # ```ruby
    # Ronin::Web::Spider.host('company.com') do |spider|
    #   spider.every_forbidden_page do |page|
    #     spider.pause!
    #   end
    # end
    # ```
    #
    # Skip the processing of a page:
    #
    # ```ruby
    # Ronin::Web::Spider.host('company.com') do |spider|
    #   spider.every_missing_page do |page|
    #     spider.skip_page!
    #   end
    # end
    # ```
    #
    # Skip the processing of links:
    #
    # ```ruby
    # Ronin::Web::Spider.host('company.com') do |spider|
    #   spider.every_url do |url|
    #     if url.path.split('/').find { |dir| dir.to_i > 1000 }
    #       spider.skip_link!
    #     end
    #   end
    # end
    # ```
    #
    # Detect when a new host name is spidered:
    #
    # ```ruby
    # Ronin::Web::Spider.domain('example.com') do |spider|
    #   spider.every_host do |host|
    #     puts "Spidring #{host} ..."
    #   end
    # end
    # ```
    #
    # Detect when a new SSL/TLS certificate is encountered:
    #
    # ```ruby
    # Ronin::Web::Spider.domain('example.com') do |spider|
    #   spider.every_cert do |cert|
    #     puts "Discovered new cert for #{cert.subject.command_name}, #{cert.subject_alt_name}"
    #   end
    # end
    # ```
    #
    # Print the MD5 checksum of every `favicon.ico` file:
    #
    # ```ruby
    # Ronin::Web::Spider.domain('example.com') do |spider|
    #   spider.every_favicon do |page|
    #     puts "#{page.url}: #{page.body.md5}"
    #   end
    # end
    # ```
    #
    # Print every HTML comment:
    #
    # ```ruby
    # Ronin::Web::Spider.domain('example.com') do |spider|
    #   spider.every_html_comment do |comment|
    #     puts comment
    #   end
    # end
    # ```
    #
    # Print all JavaScript source code:
    #
    # ```ruby
    # Ronin::Web::Spider.domain('example.com') do |spider|
    #   spider.every_javascript do |js|
    #     puts js
    #   end
    # end
    # ```
    #
    # Print every JavaScript string literal:
    #
    # ```ruby
    # Ronin::Web::Spider.domain('example.com') do |spider|
    #   spider.every_javascript_string do |str|
    #     puts str
    #   end
    # end
    # ```
    #
    # Print every JavaScript comment:
    #
    # ```ruby
    # Ronin::Web::Spider.domain('example.com') do |spider|
    #   spider.every_javascript_comment do |comment|
    #     puts comment
    #   end
    # end
    # ```
    #
    # Print every HTML and JavaScript comment:
    #
    # ```ruby
    # Ronin::Web::Spider.domain('example.com') do |spider|
    #   spider.every_comment do |comment|
    #     puts comment
    #   end
    # end
    # ```
    #
    module Spider
      #
      # Creates a new agent and begin spidering at the given URL.
      #
      # @param [URI::HTTP, String] url
      #   The URL to start spidering at.
      #
      # @param [Hash{Symbol => Object}] kwargs
      #   Additional keyword arguments. See {Agent#initialize}.
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
      # @api public
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
      #   Additional keyword arguments. See {Agent#initialize}.
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
      # @api public
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
      #   Additional keyword arguments. See {Agent#initialize}.
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
      # @api public
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
      #   Additional keyword arguments. See {Agent#initialize}.
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
      # @api public
      #
      def self.domain(name,**kwargs,&block)
        Agent.domain(name,**kwargs,&block)
      end
    end
  end
end
