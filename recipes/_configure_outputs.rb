# coding: UTF-8
#
# Cookbook Name:: cerner_splunk
# Recipe:: _configure_outputs
#
# Configures the system outputs.conf file
output_stanzas = CernerSplunk::Outputs.configure_outputs(node)

splunk_conf 'system/outputs.conf' do
  path 'system/outputs.conf'
  config output_stanzas
  not_if { output_stanzas.empty? }
  action :configure
end
