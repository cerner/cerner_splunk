source 'https://rubygems.org'

gem 'berkshelf', '~> 3.0', group: :deployment
gem 'rubocop', '~> 0.18'
gem 'foodcritic', '~> 4.0'
gem 'rspec',  '~> 3.1'

# https://github.com/opscode/chef/issues/2547
if Bundler.current_ruby.on_19?
  gem 'chef', '~> 11.0'
else
  gem 'chef', '~> 12.0'
end
