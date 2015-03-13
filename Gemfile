source 'https://rubygems.org'

gem 'berkshelf', '~> 3.0'
gem 'rubocop', '~> 0.18'
gem 'foodcritic', '~> 4.0'
gem 'rspec',  '~> 3.1'
gem 'chefspec', '~> 4.2'

# https://github.com/opscode/chef/issues/2547
if Bundler.current_ruby.on_19?
  gem 'chef', '~> 11.0'
else
  gem 'chef', '~> 12.0'
end
