# frozen_string_literal: true

#
# Cookbook Name:: cerner_splunk
# Recipe:: _restart_prep
#
# Prepares the restart resource for notifications

splunk_restart node['splunk']['package']['type'] do
  package node['splunk']['package']['type'].to_sym
  action :nothing
end
