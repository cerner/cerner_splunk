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

default['splunk']['package']['version'] = '9.0.5'
default['splunk']['package']['build'] = 'e9494146ae5c'
default['splunk']['is_cloud'] = false
default['splunk']['package']['base_url'] = 'https://download.splunk.com/products'
default['splunk']['package']['platform'] = node['os']
default['splunk']['package']['file_suffix'] =
  case node['platform_family']
  when 'rhel', 'fedora'
    if node['kernel']['machine'] == 'x86_64'
      # linux rpms of splunk/UF before 9.0.5 are a differently named package.
      if default['splunk']['package']['version'] >= '9.0.5'
        '.x86_64.rpm'
      else
      '-linux-2.6-x86_64.rpm'
      end
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

# Ignore another splunk artifact installed on a node. This is for when you want to install the universal forwarder alongisde an instance of Splunk Enterprise.
default['splunk']['ignore_already_installed_instance'] = false
