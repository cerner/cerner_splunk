source 'https://rubygems.org'

# Going forward, these should be updated to the latest versions immediately post release
chefspec_version = '= 9.2.1'

foodcritic_version = '= 16.3.0'
rubocop_version = '= 0.81.0'

chef_vault_version = '~> 4.0'

chef_version = if Bundler.current_ruby.on_25?
                 '= 14.13.11'
               elsif Bundler.current_ruby.on_26?
                 '= 15.8.23'
               else
                 '= 16.6.14'
               end

gem 'berkshelf'
gem 'chef', chef_version
gem 'chef-sugar'
gem 'chef-vault', chef_vault_version
gem 'chefspec', chefspec_version
gem 'foodcritic', foodcritic_version
gem 'rubocop', rubocop_version
gem 'ffi-libarchive'
