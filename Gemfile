source 'https://rubygems.org'

gem 'berkshelf', '~> 3.3'
gem 'rubocop', '~> 0.33'
gem 'foodcritic', '~> 4.0'
gem 'rspec', '~> 3.3'
gem 'chefspec', '~> 4.3'

# https://github.com/opscode/chef/issues/2547
if Bundler.current_ruby.on_19?
  gem 'chef', '~> 11.18'
else
  gem 'chef', '~> 12.4'
end
