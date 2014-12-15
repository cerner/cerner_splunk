# coding: UTF-8
#
# Cookbook Name:: cerner_splunk
# Recipe:: license_server
#
# Configures a License Server

fail 'License Server installation not currently supported on windows' if platform_family?('windows')

chef_gem 'nokogiri'
require 'nokogiri'

## Attributes
instance_exec :license_server, &CernerSplunk::NODE_TYPE

## Recipes
include_recipe 'cerner_splunk::_install_server'

bag = CernerSplunk::DataBag.load node['splunk']['config']['licenses'], type: :vault

unless bag
  throw "Unknown databag configured for node['splunk']['config']['licenses']"
end

data_bag_item = bag.to_hash

license_groups = data_bag_item.inject('enterprise' => {}) do |hash, (key, value)|
  unless %w(id chef_type data_bag).include? key
    doc = Nokogiri::XML value
    type = doc.at_xpath('/license/payload/type/text()').to_s
    hash[type] ||= {}
    hash[type][key] = value
  end
  hash
end

license_groups.each do |type, keys|
  prefix = "#{node['splunk']['home']}/etc/licenses/#{type}"
  directory prefix do
    owner node['splunk']['user']
    group node['splunk']['group']
    mode '0700'
  end

  keys.each do |name, value|
    file "#{prefix}/#{name}.lic" do
      content value
      owner node['splunk']['user']
      group node['splunk']['group']
      mode '0600'
      notifies :restart, 'service[splunk]'
    end
  end
end

b = ruby_block 'license cleanup' do
  block do
    license_groups.each do |type, licenses|
      existing_files = Dir.glob("#{node['splunk']['home']}/etc/licenses/#{type}/*.lic")
      expected_files = licenses.keys.collect { |name| "#{name}.lic" }
      to_delete = existing_files.delete_if { |x| expected_files.include?(File.basename(x)) }
      to_delete.each do |file|
        Chef::Log.info("ruby_block[license cleanup] deleted unconfigured license file #{file}")
        File.unlink(file)
      end
      @changed = to_delete.any?
    end
  end
  notifies :restart, 'service[splunk]'
end

# Hack to not always notify with a ruby_block
def b.updated_by_last_action?
  @changed
end

include_recipe 'cerner_splunk::_start'
