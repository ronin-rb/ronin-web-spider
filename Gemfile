source 'https://rubygems.org'

gemspec

platform :jruby do
  gem 'jruby-openssl',	'~> 0.7'
end

# gem 'spidr',  '~> 0.7', github: 'postmodern/spidr'

# gem 'ronin-support',	       '~> 1.0', github: "ronin-rb/ronin-support",
#                                        branch: 'main'

group :development do
  gem 'rake'
  gem 'rubygems-tasks', '~> 0.2'

  gem 'rspec',           '~> 3.0'
  gem 'webmock',         '~> 2.0'
  gem 'sinatra',         '~> 1.0'
  gem 'simplecov',       '~> 0.20'

  gem 'kramdown',        '~> 2.0'
  gem 'redcarpet',       platform: :mri
  gem 'yard',            '~> 0.9'
  gem 'yard-spellcheck', require: false

  gem 'dead_end',        require: false
  gem 'sord',            require: false, platform: :mri
  gem 'stackprof',       require: false, platform: :mri
end
