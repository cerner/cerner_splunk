# frozen_string_literal: true

# Cookbook Name:: cerner_splunk_test
# Recipe:: install_libarchive
#
# Installs the libarchive package to allow tar extraction to use ffi-libarchive.

# In chef 14 they attempt to embed libarchive, but it doesn't work
# So remove it and install the package ourselves.
execute 'remove files' do
  command 'rm -rf /opt/chef/embedded/lib/libarchive.so*'
  not_if { platform_family?('windows') }
end

execute 'add powertools repo' do
  command 'yum config-manager --set-enabled powertools'
  only_if { platform?('centos') && platform_version >= 8 }
end

if node['platform_family'] == 'debian'
  libarchive_package = 'libarchive-dev'

  execute 'apt-get update' do
    command 'apt-get update'
  end
else
  libarchive_package = 'libarchive-devel'
end

package libarchive_package do
  action :install
  not_if { platform_family?('windows') }
end

chef_gem 'ffi-libarchive' do
  compile_time true
end
