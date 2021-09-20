# frozen_string_literal: true

# Put this here to initialize the run state so we don't have to check it everywhere
node.run_state['cerner_splunk'] ||= {} # ~FC046

default['splunk']['node_type'] = nil
default['splunk']['cleanup'] = true

default['splunk']['external_config_directory'] =
  if node['platform_family'] == 'windows'
    "#{ENV['PROGRAMDATA']}/splunk"
  else
    '/etc/splunk'
  end

default['splunk']['package']['version'] = '8.1.6'
default['splunk']['package']['build'] = 'c1a0dd183ee5'
default['splunk']['is_cloud'] = false
default['splunk']['package']['base_url'] = 'https://d7wz6hmoaavd0.cloudfront.net/products'
default['splunk']['package']['platform'] = node['os']
default['splunk']['package']['file_suffix'] =
  case node['platform_family']
  when 'rhel', 'fedora'
    if node['kernel']['machine'] == 'x86_64'
      '-linux-2.6-x86_64.rpm'
    else
      '.i386.rpm'
    end
  when 'debian'
    if node['kernel']['machine'] == 'x86_64'
      '-linux-2.6-amd64.deb'
    else
      '-linux-2.6-intel.deb'
    end
  when 'windows'
    if node['kernel']['machine'] == 'x86_64'
      '-x64-release.msi'
    else
      '-x86-release.msi'
    end
  end
