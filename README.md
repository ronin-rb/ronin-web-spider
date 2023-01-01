# ronin-web-spider

[![CI](https://github.com/ronin-rb/ronin-web-spider/actions/workflows/ruby.yml/badge.svg)](https://github.com/ronin-rb/ronin-web-spider/actions/workflows/ruby.yml)
[![Code Climate](https://codeclimate.com/github/ronin-rb/ronin-web-spider.svg)](https://codeclimate.com/github/ronin-rb/ronin-web-spider)

* [Website](https://ronin-rb.dev/)
* [Source](https://github.com/ronin-rb/ronin-web-spider)
* [Issues](https://github.com/ronin-rb/ronin-web-spider/issues)
* [Documentation](https://ronin-rb.dev/docs/ronin-web-spider/frames)
* [Discord](https://discord.gg/6WAb3PsVX9) |
  [Twitter](https://twitter.com/ronin_rb) |
  [Mastodon](https://infosec.exchange/@ronin_rb)

## Description

ronin-web-spider is a collection of common web spidering routines using the
[spidr] gem.

## Features

* Built on top of the battle tested and versatile [spidr] gem.
* Provides additional callback methods:
  * `every_host` - yields every unique host name that's spidered.
  * `every_cert` - yields every unique SSL/TLS certificate encountered while
    spidering.
  * `every_favicon` - yields every favicon file that's encountered while
    spidering.
  * `every_html_comment` - yields every HTML comment.
  * `every_javascript` - yields all JavaScript source code from either inline
    `<script>` or `.js` files.
  * `every_javascript_string` - yields every single-quoted or double-quoted
    String literal from all JavaScript source code.
  * `every_javascript_comment` - yields every JavaScript comment.
  * `every_comment` - yields every HTML or JavaScript comment.
* Supports archiving spidered pages to a directory or git repository.
* Has 94% documentation coverage.
* Has 94% test coverage.

## Examples

Spider a host:

```ruby
require 'ronin/web/spider'

Ronin::Web::Spider.host('www.example.com') do |agent|
  agent.ever_url do |url|
    # ...
  end

  agent.every_url_like(/.../) do |url|
    # ...
  end

  agent.every_page do |page|
    # ...
  end
end
```

See [Spidr::Agent] documentation for more agent methods.

[Spidr::Agent]: https://rubydoc.info/gems/spidr/Spidr/Agent

Spider a domain:

```ruby
Ronin::Web::Spider.domain('example.com') do |agent|
  agent.every_page do |page|
    # ...
  end
end
```

Spider a website:

```ruby
Ronin::Web::Spider.site('https://www.example.com/index.html') do |agent|
  agent.every_page do |page|
    # ...
  end
end
```

## Requirements

* [Ruby] >= 3.0.0
* [spidr] ~> 0.7
* [ronin-support] ~> 1.0

## Install

```shell
$ gem install ronin-web-spider
```

### Gemfile

```ruby
gem 'ronin-web-spider', '~> 0.1'
```

### gemspec

```ruby
gem.add_dependency 'ronin-web-spider', '~> 0.1'
```

## Development

1. [Fork It!](https://github.com/ronin-rb/ronin-web-spider/fork)
2. Clone It!
3. `cd ronin-web-spider/`
4. `bundle install`
5. `git checkout -b my_feature`
6. Code It!
7. `bundle exec rake spec`
8. `git push origin my_feature`

## License

Copyright (c) 2006-2022 Hal Brodigan (postmodern.mod3 at gmail.com)

ronin-web-spider is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

ronin-web-spider is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with ronin-web-spider.  If not, see <https://www.gnu.org/licenses/>.

[Ruby]: https://www.ruby-lang.org
[spidr]: https://github.com/postmodern/spidr#readme
[ronin-support]: https://github.com/ronin-rb/ronin-support#readme
