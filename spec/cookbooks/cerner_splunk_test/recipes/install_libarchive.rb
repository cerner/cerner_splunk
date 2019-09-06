# frozen_string_literal: true

# Cookbook Name:: cerner_splunk_test
# Recipe:: install_libarchive
#
# Installs the libarchive package to allow tar extraction to use ffi-libarchive.

# In chef 14 they attempt to embed libarchive, but it doesn't work
# So remove it and install the package ourselves.
execute 'remove files' do
  command 'rm -rf /opt/chef/embedded/lib/libarchive.so*'
end

package 'libarchive-devel' do
  action :install
end

chef_gem 'ffi-libarchive' do
  compile_time true
end
