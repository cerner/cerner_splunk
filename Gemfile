source 'https://rubygems.org'

# Going forward, these should be updated to the latest versions immediately post release
chefspec_version = '= 7.1.0'
foodcritic_version = '= 11.3.1'
rubocop_version = '= 0.49.1'
chef_vault_version = '> 0.0.0'

case RUBY_VERSION
when '2.1.6'
  # Version 5.0 introduced before_notifications matchers https://github.com/sethvargo/chefspec/pull/722
  # This feature wasn't in Chef until Chef 12.6 https://github.com/chef/chef/pull/4062
  chefspec_version = '< 5.0'
  # Later versions require Ruby 2.2
  foodcritic_version = '< 8.0'
  # This is our target chef for this ruby version
  # Omnibus Definition: https://github.com/chef/omnibus-chef/blob/chef-12.4.3/config/projects/chef.rb#L36
  chef_version = '= 12.4.3'
  # Later versions require Ruby 2.2
  chef_vault_version = '< 3.0'
  # Later versions require Ruby 2.2
  gem 'fauxhai', '< 3.10'
  # Later versions require Ruby 2.2
  gem 'nio4r', '< 2.0'
  # Later versions require Ruby 2.2
  gem 'rack', '< 2.0'
  # Later versions (and thus berkshelf) won't load on chef < 12.5
  # See: https://github.com/berkshelf/ridley/issues/336
  gem 'ridley', '< 4.4.2'
else
  # https://github.com/cerner/cerner_splunk/issues/142
  chef_version = '= 12.18.31'
  gem 'molinillo', '~> 0.5.0'
end

gem 'berkshelf'
gem 'chef', chef_version
gem 'chef-vault', chef_vault_version
gem 'chefspec', chefspec_version
gem 'foodcritic', foodcritic_version
gem 'rubocop', rubocop_version
