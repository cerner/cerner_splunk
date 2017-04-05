
# frozen_string_literal: true

#
# Cookbook Name:: cerner_splunk
# Recipe:: _configure_apps
#
# Configures apps.

attributes = node['splunk']['apps']

attributes_bag = CernerSplunk::DataBag.load(attributes['bag']) || {}

# Handle the case where we might not have a cluster
cluster_data = CernerSplunk.my_cluster_data(node) || {}
# warn if the cluster's apps bag is not available on forwarders, but fail for any servers.
cluster_bag = CernerSplunk::DataBag.load(cluster_data['apps'], pick_context: CernerSplunk.keys(node), handle_load_failure: node['splunk']['node_type'] == :forwarder) || {}

bag_bag = CernerSplunk::DataBag.load(cluster_bag['bag']) || {}

apps = CernerSplunk::AppHelpers.merge_hashes(bag_bag, cluster_bag, attributes_bag, attributes)

apps.each do |app_name, app_data|
  download_data = app_data['download'] || {}

  app_type = download_data['url'] ? :splunk_app_package : :splunk_app_custom

  declare_resource(app_type, app_name) do
    action app_data['remove'] ? :uninstall : :install
    source_url download_data['url'] if download_data['url']
    version download_data['version'] if download_data['version']

    config CernerSplunk::AppHelpers.proc_conf(app_data['files'])
    files CernerSplunk::AppHelpers.proc_files(files: app_data['files'], lookups: app_data['lookups'])
    metadata app_data['permissions']
    notifies :ensure, "splunk_restart[#{node['splunk']['package']['type']}]", :immediately
  end
end
