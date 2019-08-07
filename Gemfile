source 'https://rubygems.org'

# Going forward, these should be updated to the latest versions immediately post release
chefspec_version = '= 8.0.0'
# Don't upgrade until https://github.com/Foodcritic/foodcritic/issues/760 is fixed
foodcritic_version = '= 12.3.0'
rubocop_version = '= 0.74.0'
chef_vault_version = '> 3.0'

chef_version = if Bundler.current_ruby.on_23?
                 '= 12.18.31'
               else
                 '= 14.13.11'
               end

gem 'berkshelf'
gem 'chef', chef_version
gem 'chef-sugar'
gem 'chef-vault', chef_vault_version
gem 'chefspec', chefspec_version
# https://github.com/cucumber/cucumber-ruby-core/issues/160
gem 'cucumber-core', '~> 3.2'
gem 'foodcritic', foodcritic_version
gem 'rubocop', rubocop_version
