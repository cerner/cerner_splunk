# coding: UTF-8

# Cookbook Name:: cerner_splunk
# Recipe:: _configure_shc_outputs
#
# Configures the system outputs.conf file in a search head cluster

output_stanzas = CernerSplunk::Outputs.configure_outputs(node)

splunk_template 'shcluster/_shcluster/outputs.conf' do
  stanzas output_stanzas
  not_if { output_stanzas.empty? }
  notifies :run, 'execute[apply-shcluster-bundle]'
end
