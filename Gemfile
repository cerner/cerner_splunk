source 'https://rubygems.org'

# Going forward, these should be updated to the latest versions immediately post release
chefspec_version = '= 9.3.1'
foodcritic_version = '= 16.3.0'
rubocop_version = '= 1.25.0'

chef_vault_version = '~> 4.0'

chef_version = if Bundler.current_ruby.on_27?
                 '= 16.17.18'
               elsif Bundler.current_ruby.on_30?
                 '= 17.10.0'
               else
                 '= 18.1.0'
               end

gem 'berkshelf'
gem 'chef', chef_version
gem 'chef-sugar'
gem 'chef-vault', chef_vault_version
gem 'chefspec', chefspec_version
gem 'foodcritic', foodcritic_version
gem 'rubocop', rubocop_version
gem 'ffi-libarchive'
