
# frozen_string_literal: true

default['splunk']['node_type'] = nil
default['splunk']['cleanup'] = true

default['splunk']['external_config_directory'] =
  if node['platform_family'] == 'windows'
    "#{ENV['PROGRAMDATA']}/splunk"
  else
    '/etc/splunk'
  end

default['splunk']['package']['version'] = '6.6.0'
default['splunk']['package']['build'] = '1c4f3bbe1aea'

default['splunk']['package']['base_url'] = 'https://download.splunk.com/products'
