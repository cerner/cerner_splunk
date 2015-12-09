source 'https://rubygems.org'

gem 'rubocop', '~> 0.33'
gem 'foodcritic', '~> 4.0'
gem 'rspec', '~> 3.3'
gem 'chefspec', '~> 4.3'
gem 'chef-vault'

# https://github.com/opscode/chef/issues/2547
if Bundler.current_ruby.on_19?
  gem 'chef', '~> 11.18'
  gem 'berkshelf', '~> 3.3'
  gem 'faraday', '= 0.9.1'
  gem 'ridley', '= 4.2.0'
  gem 'varia_model', '= 0.4.1'
else
  gem 'chef', '~> 12.4'
  gem 'berkshelf', '~> 4.0'
end
