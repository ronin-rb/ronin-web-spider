# ronin-web-spider

[![CI](https://github.com/ronin-rb/ronin-web-spider/actions/workflows/ruby.yml/badge.svg)](https://github.com/ronin-rb/ronin-web-spider/actions/workflows/ruby.yml)
[![Code Climate](https://codeclimate.com/github/ronin-rb/ronin-web-spider.svg)](https://codeclimate.com/github/ronin-rb/ronin-web-spider)
[![Gem Version](https://badge.fury.io/rb/ronin-web-spider.svg)](https://badge.fury.io/rb/ronin-web-spider)

* [Website](https://ronin-rb.dev/)
* [Source](https://github.com/ronin-rb/ronin-web-spider)
* [Issues](https://github.com/ronin-rb/ronin-web-spider/issues)
* [Documentation](https://ronin-rb.dev/docs/ronin-web-spider/frames)
* [Discord](https://discord.gg/6WAb3PsVX9) |
  [Mastodon](https://infosec.exchange/@ronin_rb)

## Description

ronin-web-spider is a collection of common web spidering routines using the
[spidr] gem.

## Features

* Built on top of the battle tested and versatile [spidr] gem.
* Provides additional callback methods:
  * [every_host][docs-every_host] - yields every unique host name that's
    spidered.
  * [every_cert][docs-every_cert] - yields every unique SSL/TLS certificate
    encountered while spidering.
  * [every_favicon][docs-every_favicon] - yields every favicon file that's
    encountered while spidering.
  * [every_html_comment][docs-every_html_comment] - yields every HTML comment.
  * [every_javascript][docs-every_javascript] - yields all JavaScript source
    code from either inline `<script>` or `.js` files.
  * [every_javascript_string][docs-every_javascript_string] - yields every
    single-quoted or double-quoted String literal from all JavaScript source
    code.
  * [every_javascript_relative_path_string][docs-every_javascript_relative_path_string] -
    yields every relative path JavaScript string (ex: `foo/bar`).
  * [every_javascript_absolute_path_string][docs-every_javascript_absolute_path_string] -
    yields every relative path JavaScript string (ex: `/foo/bar`).
  * [every_javascript_path_string][docs-every_javascript_path_string] -
    yields every relative path JavaScript string (ex: `foo/bar` or `/foo/bar`).
  * [every_javascript_url_string][docs-every_javascript_url_string] -
    yields every URL JavaScript string (ex: `https://example.com/foo/bar`).
  * [every_javascript_comment][docs-every_javascript_comment] - yields every
    JavaScript comment.
  * [every_comment][docs-every_comment] - yields every HTML or JavaScript
    comment.
* Supports archiving spidered pages to a directory or git repository.
* Has 97% documentation coverage.
* Has 94% test coverage.

[docs-every_host]: https://ronin-rb.dev/docs/ronin-web-spider/Ronin/Web/Spider/Agent.html#every_host-instance_method
[docs-every_cert]: https://ronin-rb.dev/docs/ronin-web-spider/Ronin/Web/Spider/Agent.html#every_cert-instance_method
[docs-every_favicon]: https://ronin-rb.dev/docs/ronin-web-spider/Ronin/Web/Spider/Agent.html#every_favicon-instance_method
[docs-every_html_comment]: https://ronin-rb.dev/docs/ronin-web-spider/Ronin/Web/Spider/Agent.html#every_html_comment-instance_method
[docs-every_javascript]: https://ronin-rb.dev/docs/ronin-web-spider/Ronin/Web/Spider/Agent.html#every_javascript-instance_method
[docs-every_javascript_string]: https://ronin-rb.dev/docs/ronin-web-spider/Ronin/Web/Spider/Agent.html#every_javascript_string-instance_method
[docs-every_javascript_relative_path_string]: https://ronin-rb.dev/docs/ronin-web-spider/Ronin/Web/Spider/Agent.html#every_javascript_relative_path_string-instance_method
[docs-every_javascript_absolute_path_string]: https://ronin-rb.dev/docs/ronin-web-spider/Ronin/Web/Spider/Agent.html#every_javascript_absolute_path_string-instance_method
[docs-every_javascript_path_string]: https://ronin-rb.dev/docs/ronin-web-spider/Ronin/Web/Spider/Agent.html#every_javascript_path_string-instance_method
[docs-every_javascript_url_string]: https://ronin-rb.dev/docs/ronin-web-spider/Ronin/Web/Spider/Agent.html#every_javascript_url_string-instance_method
[docs-every_javascript_comment]: https://ronin-rb.dev/docs/ronin-web-spider/Ronin/Web/Spider/Agent.html#every_javascript_comment-instance_method
[docs-every_comment]: https://ronin-rb.dev/docs/ronin-web-spider/Ronin/Web/Spider/Agent.html#every_comment-instance_method

## Examples

Spider a host:

```ruby
require 'ronin/web/spider'

Ronin::Web::Spider.start_at('http://tenderlovemaking.com/') do |agent|
  # ...
end
```

Spider a host:

```ruby
Ronin::Web::Spider.host('solnic.eu') do |agent|
  # ...
end
```

Spider a domain (and any sub-domains):

```ruby
Ronin::Web::Spider.domain('ruby-lang.org') do |agent|
  # ...
end
```

Spider a site:

```ruby
Ronin::Web::Spider.site('http://www.rubyflow.com/') do |agent|
  # ...
end
```

Spider multiple hosts:

```ruby
Ronin::Web::Spider.start_at('http://company.com/', hosts: ['company.com', /host[\d]+\.company\.com/]) do |agent|
  # ...
end
```

Do not spider certain links:

```ruby
Ronin::Web::Spider.site('http://company.com/', ignore_links: [%r{^/blog/}]) do |agent|
  # ...
end
```

Do not spider links on certain ports:

```ruby
Ronin::Web::Spider.site('http://company.com/', ignore_ports: [8000, 8010, 8080]) do |agent|
  # ...
end
```

Do not spider links blacklisted in robots.txt:

```ruby
Ronin::Web::Spider.site('http://company.com/', robots: true) do |agent|
  # ...
end
```

Print out visited URLs:

```ruby
Ronin::Web::Spider.site('http://www.rubyinside.com/') do |spider|
  spider.every_url { |url| puts url }
end
```

Build a URL map of a site:

```ruby
url_map = Hash.new { |hash,key| hash[key] = [] }

Ronin::Web::Spider.site('http://intranet.com/') do |spider|
  spider.every_link do |origin,dest|
    url_map[dest] << origin
  end
end
```

Print out the URLs that could not be requested:

```ruby
Ronin::Web::Spider.site('http://company.com/') do |spider|
  spider.every_failed_url { |url| puts url }
end
```

Finds all pages which have broken links:

```ruby
url_map = Hash.new { |hash,key| hash[key] = [] }

spider = Ronin::Web::Spider.site('http://intranet.com/') do |spider|
  spider.every_link do |origin,dest|
    url_map[dest] << origin
  end
end

spider.failures.each do |url|
  puts "Broken link #{url} found in:"

  url_map[url].each { |page| puts "  #{page}" }
end
```

Search HTML and XML pages:

```ruby
Ronin::Web::Spider.site('http://company.com/') do |spider|
  spider.every_page do |page|
    puts ">>> #{page.url}"

    page.search('//meta').each do |meta|
      name = (meta.attributes['name'] || meta.attributes['http-equiv'])
      value = meta.attributes['content']

      puts "  #{name} = #{value}"
    end
  end
end
```

Print out the titles from every page:

```ruby
Ronin::Web::Spider.site('https://www.ruby-lang.org/') do |spider|
  spider.every_html_page do |page|
    puts page.title
  end
end
```

Print out every HTTP redirect:

```ruby
Ronin::Web::Spider.host('company.com') do |spider|
  spider.every_redirect_page do |page|
    puts "#{page.url} -> #{page.headers['Location']}"
  end
end
```

Find what kinds of web servers a host is using, by accessing the headers:

```ruby
servers = Set[]

Ronin::Web::Spider.host('company.com') do |spider|
  spider.all_headers do |headers|
    servers << headers['server']
  end
end
```

Pause the spider on a forbidden page:

```ruby
Ronin::Web::Spider.host('company.com') do |spider|
  spider.every_forbidden_page do |page|
    spider.pause!
  end
end
```

Skip the processing of a page:

```ruby
Ronin::Web::Spider.host('company.com') do |spider|
  spider.every_missing_page do |page|
    spider.skip_page!
  end
end
```

Skip the processing of links:

```ruby
Ronin::Web::Spider.host('company.com') do |spider|
  spider.every_url do |url|
    if url.path.split('/').find { |dir| dir.to_i > 1000 }
      spider.skip_link!
    end
  end
end
```

Detect when a new host name is spidered:

```ruby
Ronin::Web::Spider.domain('example.com') do |spider|
  spider.every_host do |host|
    puts "Spidering #{host} ..."
  end
end
```

Detect when a new SSL/TLS certificate is encountered:

```ruby
Ronin::Web::Spider.domain('example.com') do |spider|
  spider.every_cert do |cert|
    puts "Discovered new cert for #{cert.subject.command_name}, #{cert.subject_alt_name}"
  end
end
```

Print the MD5 checksum of every `favicon.ico` file:

```ruby
Ronin::Web::Spider.domain('example.com') do |spider|
  spider.every_favicon do |page|
    puts "#{page.url}: #{page.body.md5}"
  end
end
```

Print every HTML comment:

```ruby
Ronin::Web::Spider.domain('example.com') do |spider|
  spider.every_html_comment do |comment|
    puts comment
  end
end
```

Print all JavaScript source code:

```ruby
Ronin::Web::Spider.domain('example.com') do |spider|
  spider.every_javascript do |js|
    puts js
  end
end
```

Print every JavaScript string literal:

```ruby
Ronin::Web::Spider.domain('example.com') do |spider|
  spider.every_javascript_string do |str|
    puts str
  end
end
```

Print every JavaScript URL string literal:

```ruby
Ronin::Web::Spider.domain('example.com') do |spider|
  spider.every_javascript_url_string do |url|
    puts url
  end
end
```

Print every JavaScript comment:

```ruby
Ronin::Web::Spider.domain('example.com') do |spider|
  spider.every_javascript_comment do |comment|
    puts comment
  end
end
```

Print every HTML and JavaScript comment:

```ruby
Ronin::Web::Spider.domain('example.com') do |spider|
  spider.every_comment do |comment|
    puts comment
  end
end
```

Spider a host and archive every web page:

```ruby
require 'ronin/web/spider'
require 'ronin/web/spider/archive'

Ronin::Web::Spider::Archive.open('path/to/root') do |archive|
  Ronin::Web::Spider.every_page(host: 'example.com') do |page|
    archive.write(page.url,page.body)
  end
end
```

Spider a host and archive every web page to a Git repository:

```ruby
require 'ronin/web/spider/git_archive'
require 'ronin/web/spider'
require 'date'

Ronin::Web::Spider::GitArchive.open('path/to/root') do |archive|
  archive.commit("Updated #{Date.today}") do
    Ronin::Web::Spider.every_page(host: 'example.com') do |page|
      archive.write(page.url,page.body)
    end
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

Copyright (c) 2006-2025 Hal Brodigan (postmodern.mod3 at gmail.com)

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
