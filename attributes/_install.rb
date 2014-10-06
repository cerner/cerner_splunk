# coding: UTF-8

default[:splunk][:node_type] = nil

default[:splunk][:external_config_directory] = '/etc/splunk'

default[:splunk][:package][:version] = '6.0.3'
default[:splunk][:package][:build] = '204106'

default[:splunk][:package][:base_url] = 'http://download.splunk.com/releases'
default[:splunk][:package][:platform] = node[:os]
default[:splunk][:package][:file_suffix] =
  case node[:platform_family]
  when 'rhel', 'fedora'
    if node[:kernel][:machine] == 'x86_64'
      '-linux-2.6-x86_64.rpm'
    else
      '.i386.rpm'
    end
  when 'debian'
    if node[:kernel][:machine] == 'x86_64'
      '-linux-2.6-amd64.deb'
    else
      '-linux-2.6-intel.deb'
    end
  end

default[:splunk][:package][:provider] =
  case node[:platform_family]
  when 'rhel', 'fedora'
    Chef::Provider::Package::Rpm
  when 'debian'
    Chef::Provider::Package::Dpkg
  end
