# frozen_string_literal: true

# Cookbook Name:: cerner_splunk
# Recipe:: license_server
#
# Configures a License Server

fail 'License Server installation not currently supported on windows' if platform_family?('windows')

require 'nokogiri'
require 'digest'
require 'fileutils'

## Attributes
instance_exec :license_server, &CernerSplunk::NODE_TYPE

bag = CernerSplunk::DataBag.load node['splunk']['config']['licenses'], secret: node['splunk']['data_bag_secret']

throw "Unknown databag configured for node['splunk']['config']['licenses']" unless bag

data_bag_item = bag.to_hash
total_available_license_quota = 0

license_groups = data_bag_item.inject({}) do |hash, (key, value)|
  unless %w[id chef_type data_bag].include? key
    doc = Nokogiri::XML value
    sourcetypes = doc.search('//sourcetype').map(&:text).join
    type = doc.at_xpath('/license/payload/type/text()').to_s
    type = "#{type}_#{Digest::SHA256.hexdigest(sourcetypes).upcase}" if type == 'fixed-sourcetype'
    quota = doc.at_xpath('/license/payload/quota/text()').to_s.to_i
    expiration_time = doc.at_xpath('/license/payload/expiration_time/text()').to_s.to_i
    total_available_license_quota += quota if (['enterprise', "fixed-sourcetype_#{Digest::SHA256.hexdigest(sourcetypes).upcase}"].include? type) && expiration_time > Time.now.to_i
    hash[type] ||= {}
    fail 'Multiple license types are not currently supported' if hash.length > 1

    hash[type][key] = value
  end
  hash
end

node.run_state['license_type'] = license_groups.keys.first

## Recipes
include_recipe 'cerner_splunk::_install_server'

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

b = ruby_block 'license cleanup' do # ~FC014
  block do
    existing_directory = Dir.glob("#{node['splunk']['home']}/etc/licenses/*")
    existing_directory.each do |dir|
      next if license_groups.keys.include? File.basename(dir)

      Chef::Log.info("ruby_block[license cleanup] deleted unconfigured license directory #{dir}")
      FileUtils.rm_rf(dir)
    end
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
