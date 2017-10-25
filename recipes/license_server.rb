# coding: UTF-8

# Cookbook Name:: cerner_splunk
# Recipe:: license_server
#
# Configures a License Server

fail 'License Server installation not currently supported on windows' if platform_family?('windows')

include_recipe 'xml::ruby'
require 'nokogiri'

## Attributes
instance_exec :license_server, &CernerSplunk::NODE_TYPE

## Recipes
include_recipe 'cerner_splunk::_install_server'

bag = CernerSplunk::DataBag.load node['splunk']['config']['licenses'], secret: node['splunk']['data_bag_secret']

unless bag
  throw "Unknown databag configured for node['splunk']['config']['licenses']"
end

data_bag_item = bag.to_hash
total_available_license_quota = 0

license_groups = data_bag_item.inject('enterprise' => {}) do |hash, (key, value)|
  unless %w[id chef_type data_bag].include? key
    doc = Nokogiri::XML value
    type = doc.at_xpath('/license/payload/type/text()').to_s
    quota = doc.at_xpath('/license/payload/quota/text()').to_s.to_i
    expiration_time = doc.at_xpath('/license/payload/expiration_time/text()').to_s.to_i
    total_available_license_quota += quota if type == 'enterprise' && expiration_time > Time.now.to_i
    hash[type] ||= {}
    hash[type][key] = value
  end
  hash
end

unless node.run_state['cerner_splunk']['total_allotted_pool_size'].nil?
  total_allotted_pool_size = node.run_state['cerner_splunk']['total_allotted_pool_size']
  fail "Sum of pool sizes is #{CernerSplunk.human_readable_size total_allotted_pool_size}. Exceeds total available pool size of #{CernerSplunk.human_readable_size total_available_license_quota}." if total_allotted_pool_size > total_available_license_quota
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
      sensitive true
      notifies :touch, 'file[splunk-marker]', :immediately
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
  notifies :touch, 'file[splunk-marker]', :immediately
end

# Hack to not always notify with a ruby_block
def b.updated_by_last_action?
  @changed
end

include_recipe 'cerner_splunk::_start'
