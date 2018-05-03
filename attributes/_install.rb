# coding: UTF-8

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

default['splunk']['package']['version'] = '7.0.3'
default['splunk']['package']['build'] = 'fa31da744b51'

default['splunk']['package']['base_url'] = 'https://download.splunk.com/products'
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

default['splunk']['package']['provider'] =
  case node['platform_family']
  when 'rhel', 'fedora'
    Chef::Provider::Package::Rpm
  when 'debian'
    Chef::Provider::Package::Dpkg
  when 'windows'
    Chef::Provider::Package::Windows
  end
