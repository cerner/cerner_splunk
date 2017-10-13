# coding: UTF-8

# Cookbook Name:: cerner_splunk
# Recipe:: _configure_apps
#
# Configures apps.

attributes = node['splunk']['apps']

attributes_bag = CernerSplunk::DataBag.load(attributes['bag'], secret: node['splunk']['data_bag_secret']) || {}

# Handle the case where we might not have a cluster
cluster_data = CernerSplunk.my_cluster_data(node) || {}
# warn if the cluster's apps bag is not available on forwarders, but fail for any servers.
cluster_bag = CernerSplunk::DataBag.load(cluster_data['apps'], pick_context: CernerSplunk.keys(node), handle_load_failure: node['splunk']['node_type'] == :forwarder, secret: node['splunk']['data_bag_secret']) || {}

bag_bag = CernerSplunk::DataBag.load(cluster_bag['bag'], secret: node['splunk']['data_bag_secret']) || {}

apps = CernerSplunk::SplunkApp.merge_hashes(bag_bag, cluster_bag, attributes_bag, attributes)

apps.each do |app_name, app_data|
  download_data = app_data['download'] || {}

  splunk_app app_name do
    apps_dir "#{node['splunk']['home']}/etc/apps"
    action app_data['remove'] ? :remove : :create
    url download_data['url']
    version download_data['version']
    local app_data['local']
    files app_data['files']
    lookups app_data['lookups']
    permissions app_data['permissions']
    notifies :touch, 'file[splunk-marker]', :immediately
  end
end
