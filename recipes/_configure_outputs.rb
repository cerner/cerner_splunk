# coding: UTF-8

# Cookbook Name:: cerner_splunk
# Recipe:: _configure_outputs
#
# Configures the system outputs.conf file
output_stanzas = CernerSplunk::Outputs.configure_outputs(node)

splunk_template 'system/outputs.conf' do
  stanzas output_stanzas
  not_if { output_stanzas.empty? }
  notifies :touch, 'file[splunk-marker]', :immediately
end
