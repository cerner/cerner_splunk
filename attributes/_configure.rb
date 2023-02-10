# frozen_string_literal: true

default['splunk']['config']['host'] = node['ec2'] ? node['ec2']['instance_id'] : (node['fqdn'] || node['machinename'] || node['hostname'])

default['splunk']['config']['licenses'] = nil
default['splunk']['config']['ui_prefs']['default'] = {
  'dispatch.earliest_time' => '@d',
  'dispatch.latest_time' => 'now',
  'display.prefs.enableMetaData' => 0,
  'display.prefs.showDataSummary' => 0
}

# References 0 to many cluster configurations (arrays of Strings of data_bag/data_bag_item)
default['splunk']['config']['clusters'] = []
default['splunk']['config']['roles'] = nil
default['splunk']['config']['authentication'] = nil

# Attributes used for configuring SH clustering
default['splunk']['bootstrap_shc_member'] = false
# This is only used for SH Clustering identifying address to the management port
default['splunk']['mgmt_host'] = nil
default['splunk']['mgmt_interface'] = node['network']['default_interface']

default['splunk']['free_license'] = false

default['splunk']['main_project_index'] = nil
default['splunk']['monitors'] = []
default['splunk']['apps'] = {}
default['splunk']['logs'] = {}

default['splunk']['config']['assumed_index'] = 'main'

# Attribute used to point a heavy forwarder to license master
default['splunk']['heavy_forwarder']['use_license_uri'] = false

# Disable site awareness for multisite clustering.
default['splunk']['forwarder_site'] = 'site0'

# Give options to set splunk enable boot-start arguments
default['splunk']['boot_start_args'] =
  if platform_family? 'rhel', 'fedora', 'amazon'
    case node['platform_version'].to_i
    when 6
      '-systemd-managed 0'
    when 7, 8
      '-systemd-managed 1'
    else
      '-systemd-managed 0'
    end
  else
    '-systemd-managed 0'
  end

# Default systemd file location based on default systemd unit file name
default['splunk']['systemd_file_location'] = '/etc/systemd/system/splunk.service'
default['splunk']['systemd_unit_file_name'] = 'splunk'
default['splunk']['config']['sslPassword'] = 'password'
