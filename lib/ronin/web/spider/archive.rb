# frozen_string_literal: true
#
# ronin-web-spider - A collection of common web spidering routines.
#
# Copyright (c) 2022 Hal Brodigan (postmodern.mod3 at gmail.com)
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

require 'fileutils'

module Ronin
  module Web
    module Spider
      #
      # Represents a web archive directory.
      #
      # ## Example
      #
      # Spider a host and archive every web page:
      #
      #     require 'ronin/web/spider'
      #     require 'ronin/web/spider/archive'
      #
      #     Ronin::Web::Spider::Archive.open('path/to/root') do |archive|
      #       Ronin::Web::Spider.every_page(host: 'example.com') do |page|
      #         archive.write(page.url,page.body)
      #       end
      #     end
      #
      class Archive

        # The path to the archive root directory.
        #
        # @return [String]
        attr_reader :root

        #
        # Initializes the archive.
        #
        # @param [String] root
        #   The path to the root directory.
        #
        def initialize(root)
          @root = File.expand_path(root)
        end

        #
        # Creates the archive and the archive's directory, if it already does
        # not exist.
        #
        # @param [String] root
        #   The path to the new archive.
        #
        # @yield [archive]
        #   If a block is given, it will be passed the newly created archive.
        #
        # @yieldparam [Archive] archive
        #   The newly created archive.
        #
        # @return [GitArchive]
        #   The newly created archive.
        #
        def self.open(root)
          archive = new(root)

          FileUtils.mkdir_p(archive.root)

          yield archive if block_given?
          return archive
        end

        #
        # Archives a webpage.
        #
        # @param [URI::HTTP] url
        #   The URL of the response.
        #
        # @param [String] body
        #   The response body to save.
        #
        # @return [String]
        #   The full path to the archived page.
        #
        def write(url,body)
          absolute_path = File.join(@root,url.request_uri[1..])
          absolute_path << 'index.html' if absolute_path.end_with?('/')

          parent_dir = File.dirname(absolute_path)

          FileUtils.mkdir_p(parent_dir) unless File.directory?(parent_dir)
          File.write(absolute_path,body)
          return absolute_path
        end

        #
        # Converts the archive to a String.
        #
        # @return [String]
        #   The path of the archive directory.
        #
        def to_s
          @root
        end

      end
    end
  end
end
