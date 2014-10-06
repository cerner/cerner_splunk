# coding: UTF-8
#
# Cookbook Name:: cerner_splunk
# Resource:: forwarder_monitors
#
# Drop in replacement for the existing splunk_forwarder_monitors

actions :install, :delete

attribute :app,      kind_of: String, name_attribute: true, regex: [/^[A-Za-z0-9_-]/]
attribute :index,    kind_of: String, required: false
attribute :monitors, kind_of: Array, default: []

def initialize(name, run_context = nil)
  super
  @resource_name = :splunk_forwarder_monitors
  @index = node[:splunk][:main_project_index]
  @action = :install
end

def after_created
  super
  Chef::Application.fatal!('node[:splunk][:home] is not defined, ensure your run list is configured to run the cerner_splunk recipe before this point!') unless node[:splunk][:home]
end
