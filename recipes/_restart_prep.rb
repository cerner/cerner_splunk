# frozen_string_literal: true

#
# Cookbook Name:: cerner_splunk
# Recipe:: _restart_prep
#
# Prepares the restart resource for notifications

splunk_restart node['splunk']['package']['type'] do
  package node['splunk']['package']['type'].to_sym # I think Chefspec is not playing nice with symbols
  supports ensure: true, check: true, clear: true
  action :nothing
end
