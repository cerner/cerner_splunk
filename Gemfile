source 'https://rubygems.org'

# Going forward, these should be updated to the latest versions immediately post release
chefspec_version = '= 7.0.0'
foodcritic_version = '= 11.0.0'
rubocop_version = '= 0.48.1'
chef_vault_version = '> 3.0'

chef_version = if Bundler.current_ruby.on_23?
                 '= 12.18.31'
               else
                 '= 14.5.27'
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
