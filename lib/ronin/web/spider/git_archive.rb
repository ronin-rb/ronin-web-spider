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

require 'ronin/web/spider/archive'
require 'ronin/web/spider/exceptions'

module Ronin
  module Web
    module Spider
      #
      # Represents a web archive directory that is backed by Git.
      #
      # ## Example
      #
      # Spider a host and archive every web page to a Git repository:
      #
      #     require 'ronin/web/spider'
      #     require 'ronin/web/spider/git_archive'
      #     require 'date'
      #
      #     Ronin::Web::Spider::GitArchive.open('path/to/root') do |archive|
      #       archive.commit("Updated #{Date.today}") do
      #         Ronin::Web::Spider.every_page(host: 'example.com') do |page|
      #           archive.write(page.url,page.body)
      #         end
      #       end
      #     end
      #
      class GitArchive < Archive

        #
        # Creates the Git archive, if it already does not exist.
        #
        # @param [String] root
        #   The path to the new Git archive.
        #
        # @yield [archive]
        #   If a block is given, it will be passed the newly created Git
        #   archive.
        #
        # @yieldparam [GitArchive] archive
        #   The newly created Git archive.
        #
        # @return [GitArchive]
        #   The newly created Git archive.
        #
        def self.open(root)
          super(root) do |archive|
            archive.init unless archive.git?

            yield archive if block_given?
          end
        end

        #
        # Determines if the git repository has been initialized.
        #
        # @return [Boolean]
        #
        def git?
          File.directory?(File.join(@root,'.git'))
        end

        #
        # Initializes the Git repository.
        #
        # @return [true]
        #   Indicates the Git repository was successfully initialized.
        #
        # @raise [GitError]
        #   Indicates that the `git` command exited with an error.
        #
        # @raise [GitNotInstalled]
        #   Indicates that `git` was not installed or could not be found in the
        #   `$PATH` environment variable.
        #
        def init
          git('init')
        end

        #
        # Saves a webpage to the Git archive.
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
        # @raise [GitError]
        #   Indicates that the `git` command exited with an error.
        #
        # @raise [GitNotInstalled]
        #   Indicates that `git` was not installed or could not be found in the
        #   `$PATH` environment variable.
        #
        def write(url,body)
          absolute_path = super(url,body)

          git('add',absolute_path)
          return absolute_path
        end

        #
        # Commits changes to the Git archive.
        #
        # @param [String] message
        #   The commit message.
        #
        # @yield [self]
        #   If a block is given it will be called before committing any changes.
        #
        # @return [true]
        #   Indicates whether the changes were successfully committed.
        #
        # @raise [GitError]
        #   Indicates the `git` command exited with an error.
        #
        # @raise [GitNotInstalled]
        #   Indicates that `git` was not installed or could not be found in the
        #   `$PATH` environment variable.
        #
        # @example
        #   archive.write(url,response.body)
        #   archive.commit "Updated #{Date.today}"
        #
        # @example with a block:
        #   archive.commit("Updated #{Date.today}") do
        #     Ronin::Web::Spider.every_page(host: 'example.com') do |page|
        #       archive.write(page.url,page.body)
        #     end
        #   end
        #
        def commit(message)
          yield self if block_given?

          git('commit','-m',message.to_s)
        end

        private

        #
        # Executes a `git` command in the archive root directory..
        #
        # @param [Array<String>] args
        #   Additional arguments for the `git` command.
        #
        # @return [true]
        #   Indicates that the `git` command executed successfully.
        #
        # @raise [GitError]
        #   Indicates that the `git` command exited with an error.
        #
        # @raise [GitNotInstalled]
        #   Indicates that `git` was not installed or could not be found in the
        #   `$PATH` environment variable.
        #
        def git(*args)
          command = ['git', '-C', @root]
          command.concat(args)

          case system(*command)
          when false
            raise(GitError,"git command failed: #{command.join(' ')}")
          when nil
            raise(GitNotInstalled,"the git command was not found")
          else
            true
          end
        end

      end
    end
  end
end
