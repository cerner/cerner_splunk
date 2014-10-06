# coding: UTF-8
default[:splunk][:config][:host] = node[:ec2] ? node[:ec2][:instance_id] : (node[:fqdn] || node[:machinename] || node[:hostname])

default[:splunk][:config][:licenses] = nil
default[:splunk][:config][:ui_prefs][:default] = {
  'dispatch.earliest_time' => '@d',
  'dispatch.latest_time' => 'now'
}

# References 0 to many cluster configurations (arrays of Strings of data_bag/data_bag_item)
default[:splunk][:config][:clusters] = []
default[:splunk][:config][:roles] = nil
default[:splunk][:config][:authentication] = nil

default[:splunk][:free_license] = false

# Legacy attributes from the aeon-operations cookbook
default[:splunk][:main_project_index] = nil
default[:splunk][:monitors] = []

# Flag attributes for warnings
default[:splunk][:flags][:index_checks_fail] = true

default[:splunk][:config][:assumed_index] = 'main'
