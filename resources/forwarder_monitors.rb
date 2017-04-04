
# frozen_string_literal: true

#
# Cookbook Name:: cerner_splunk
# Resource:: forwarder_monitors
#

resource_name :splunk_forwarder_monitors
provides :cerner_splunk_forwarder_monitors

property :app, String, name_property: true, regex: [/^[A-Za-z0-9_-]/]
property :index, String, default: lazy { node['splunk']['main_project_index'] }
property :monitors, Array, default: []

def after_created
  return if node['splunk']['home']
  Chef::Application.fatal!("node['splunk']['home'] is not defined, ensure your run list is configured to run the cerner_splunk recipe before this point!")
end

action :install do
  input_stanzas = CernerSplunk::LWRP.convert_monitors(node, new_resource.monitors, new_resource.index)

  splunk_app_custom new_resource.app do
    configs(proc do
      splunk_conf 'inputs.conf' do
        config input_stanzas
      end
    end)
    notifies :ensure, "splunk_restart[#{node['splunk']['package']['type']}]", :immediately
  end
end

action :delete do
  splunk_app new_resource.app do
    action :uninstall
  end
end
