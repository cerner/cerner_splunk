source 'https://rubygems.org'

# Going forward, these should be updated to the latest versions immediately post release
chefspec_version = if Bundler.current_ruby.on_23?
                 '= 7.3.4'
               else
                 '= 9.2.1'
               end

foodcritic_version = '= 16.3.0'
# rubocop 0.82 drops support for ruby 2.3
rubocop_version = '= 0.81.0'
# chef-vault 4.x drops support for ruby 2.3
chef_vault_version = '~> 3.0'

chef_version = if Bundler.current_ruby.on_23?
                 '= 12.18.31'
               elsif Bundler.current_ruby.on_25?
                 '= 14.13.11'
               elsif Bundler.current_ruby.on_26?
                 '= 15.8.23'
               else
                 '= 16.6.14'
               end

if Bundler.current_ruby.on_23?
    # The latest version of faraday is not compatible with older versions of berkshelf
    gem 'faraday', '< 0.16.0'
end

gem 'berkshelf'
gem 'chef', chef_version
gem 'chef-sugar'
gem 'chef-vault', chef_vault_version
gem 'chefspec', chefspec_version
gem 'foodcritic', foodcritic_version
gem 'rubocop', rubocop_version
gem 'ffi-libarchive'
