# coding: UTF-8
#
# Cookbook Name:: cerner_splunk
# Recipe:: _configure_apps
#
# Configures apps.

attributes = node[:splunk][:apps]

attributes_bag = CernerSplunk::DataBag.load(attributes['bag']) || {}

cluster_bag = CernerSplunk::DataBag.load(CernerSplunk.my_cluster_data(node)['apps'], pick_context: CernerSplunk.keys(node)) || {}

bag_bag = CernerSplunk::DataBag.load(cluster_bag['bag']) || {}

apps = CernerSplunk::SplunkApp.merge_hashes(bag_bag, cluster_bag, attributes_bag, attributes)

apps.each do |app_name, app_data|
  splunk_app app_name do
    apps_dir "#{node[:splunk][:home]}/etc/apps"
    action app_data['remove'] ? :remove : :create
    local app_data['local']
    files app_data['files']
    permissions app_data['permissions']
    notifies :restart, 'service[splunk]'
  end
end
