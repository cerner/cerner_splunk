# coding: UTF-8

# Cookbook Name:: cerner_splunk
# Recipe:: _configure_server
#
# Configures the system server.conf file

server_stanzas = {
  'general' => {
    'serverName' => node['splunk']['config']['host']
  },
  'sslConfig' => {}
}

SLAVE_ONLY_CONFIGS = %w[
  max_replication_errors
  register_replication_address
  register_forwarder_address
  register_search_address
  heartbeat_period
  enableS2SHeartbeat
].freeze

MASTER_ONLY_CONFIGS = %w[
  replication_factor
  search_factor
  heartbeat_timeout
  restart_timeout
  quiet_period
  generation_poll_interval
  searchable_targets
  target_wait_time
  commit_retry_time
].freeze

encrypt_password = CernerSplunk::ConfTemplate::Transform.splunk_encrypt node: node
encrypt_noxor_password = CernerSplunk::ConfTemplate::Transform.splunk_encrypt node: node, xor: false

# default pass4SymmKey value is 'changeme'
server_stanzas['general']['pass4SymmKey'] = CernerSplunk::ConfTemplate.compose encrypt_password, CernerSplunk::ConfTemplate::Value.constant(value: 'changeme')
# default sslPassword value is 'password'
server_stanzas['sslConfig']['sslPassword'] = CernerSplunk::ConfTemplate.compose encrypt_noxor_password, CernerSplunk::ConfTemplate::Value.constant(value: 'password')

case node['splunk']['node_type']
when :forwarder
  # Apparently there is no option to configure site awareness for different multisite clusters.
  # https://answers.splunk.com/answers/590556/how-to-configure-site-awareness-on-forwarders-for.html
  server_stanzas['general']['site'] = node['splunk']['forwarder_site']
when :search_head, :shc_search_head, :shc_captain, :server
  clusters = CernerSplunk.all_clusters(node).collect do |(cluster, bag)|
    stanza = "clustermaster:#{cluster}"
    master_uri = bag['master_uri'] || ''
    settings = bag['settings'] || {}
    pass = settings['pass4SymmKey'] || ''

    next if master_uri.empty?

    server_stanzas[stanza] = {}
    server_stanzas[stanza]['master_uri'] = master_uri
    server_stanzas[stanza]['pass4SymmKey'] = CernerSplunk::ConfTemplate.compose encrypt_password, CernerSplunk::ConfTemplate::Value.constant(value: pass) unless pass.empty?
    if CernerSplunk.multisite_cluster?(bag, cluster)
      server_stanzas[stanza]['multisite'] = true
      server_stanzas[stanza]['site'] = bag['disable_search_affinity'] == true ? 'site0' : bag['site']
    else
      # Should be explicitly set to false to avoid spamming _internal logs
      server_stanzas[stanza]['multisite'] = false
    end
    stanza
  end

  clusters.reject!(&:nil?)

  if clusters.any?
    server_stanzas['clustering'] = {}
    server_stanzas['clustering']['mode'] = 'searchhead'
    server_stanzas['clustering']['master_uri'] = clusters.join(',')
  end
when :cluster_master
  cluster, bag = CernerSplunk.my_cluster(node)

  if bag['indexer_discovery'] == true
    indexer_discovery_settings = ((bag['indexer_discovery_settings'] && bag['indexer_discovery_settings']['master_configs']) || {}).reject do |k, _|
      k.start_with?('_cerner_splunk')
    end
    pass = (bag['indexer_discovery_settings'] && bag['indexer_discovery_settings']['pass4SymmKey']) || nil

    server_stanzas['indexer_discovery'] = indexer_discovery_settings
    server_stanzas['indexer_discovery']['pass4SymmKey'] = CernerSplunk::ConfTemplate.compose encrypt_password, CernerSplunk::ConfTemplate::Value.constant(value: pass) if pass
  end

  is_multisite = CernerSplunk.multisite_cluster?(bag, cluster)
  if is_multisite
    server_stanzas['general']['site'] = bag['site']
    multisite_configs = CernerSplunk::DataBag.load(bag['multisite'], secret: node['splunk']['data_bag_secret']) || {}
    fail "sites attribute not configured in the multisite cluster databag: #{bag['multisite']}" if multisite_configs['sites'].nil? || multisite_configs['sites'].empty?
    available_sites = multisite_configs['sites'].map { |site| CernerSplunk::DataBag.load(site, secret: node['splunk']['data_bag_secret'])['site'] }
    settings = (multisite_configs['multisite_settings'] || {}).reject do |k, _|
      k.start_with?('_cerner_splunk')
    end

    pass = settings.delete('pass4SymmKey')
    server_stanzas['clustering'] = settings
    server_stanzas['clustering']['multisite'] = true
    server_stanzas['clustering']['available_sites'] = available_sites.join(',')
  else
    settings = (bag['settings'] || {}).reject do |k, _|
      k.start_with?('_cerner_splunk') || SLAVE_ONLY_CONFIGS.include?(k)
    end
    pass = settings.delete('pass4SymmKey')
    server_stanzas['clustering'] = settings
  end
  server_stanzas['clustering']['mode'] = 'master'
  server_stanzas['clustering']['pass4SymmKey'] = CernerSplunk::ConfTemplate.compose encrypt_password, CernerSplunk::ConfTemplate::Value.constant(value: pass) if pass
when :cluster_slave
  cluster, bag = CernerSplunk.my_cluster(node)

  server_stanzas['general']['site'] = bag['site'] if CernerSplunk.multisite_cluster?(bag, cluster)
  master_uri = bag['master_uri'] || ''
  replication_ports = bag['replication_ports'] || {}
  settings = (bag['settings'] || {}).reject do |k, _|
    k.start_with?('_cerner_splunk') || MASTER_ONLY_CONFIGS.include?(k)
  end

  throw "Missing master uri for cluster '#{cluster}'" if master_uri.empty?
  throw "Missing replication port configuration for cluster '#{cluster}'" if replication_ports.empty?

  pass = settings.delete('pass4SymmKey')

  server_stanzas['clustering'] = settings
  server_stanzas['clustering']['mode'] = 'slave'
  server_stanzas['clustering']['pass4SymmKey'] = CernerSplunk::ConfTemplate.compose encrypt_password, CernerSplunk::ConfTemplate::Value.constant(value: pass) if pass
  server_stanzas['clustering']['master_uri'] = master_uri

  replication_ports.each do |port, port_settings|
    ssl = port_settings['_cerner_splunk_ssl'] == true
    stanza = ssl ? "replication_port-ssl://#{port}" : "replication_port://#{port}"
    server_stanzas[stanza] = port_settings.reject do |k, _|
      k.start_with? '_cerner_splunk'
    end
  end
when :shc_deployer
  bag = CernerSplunk.my_cluster_data(node)
  settings = (bag['shc_settings'] || {}).reject do |k, _|
    k.start_with?('_cerner_splunk')
  end
  pass = settings.delete('pass4SymmKey')

  server_stanzas['shclustering'] = settings
  server_stanzas['shclustering']['pass4SymmKey'] = CernerSplunk::ConfTemplate.compose encrypt_password, CernerSplunk::ConfTemplate::Value.constant(value: pass) if pass
end

# Search Head Cluster configuration
if %i[shc_search_head shc_captain].include? node['splunk']['node_type']
  cluster, bag = CernerSplunk.my_cluster(node)
  deployer_uri = bag['deployer_uri'] || ''
  replication_ports = bag['shc_replication_ports'] || bag['replication_ports'] || {}
  settings = (bag['shc_settings'] || {}).reject do |k, _|
    k.start_with?('_cerner_splunk')
  end
  pass = settings.delete('pass4SymmKey')

  fail "Missing deployer URI for #{cluster}" if deployer_uri.empty?
  fail "Missing replication port configuration for cluster '#{cluster}'" if replication_ports.empty?

  replication_ports.each do |port, port_settings|
    ssl = port_settings['_cerner_splunk_ssl'] == true
    stanza = ssl ? "replication_port-ssl://#{port}" : "replication_port://#{port}"
    server_stanzas[stanza] = port_settings.reject do |k, _|
      k.start_with? '_cerner_splunk'
    end
  end

  path = "#{node['splunk']['home']}/etc/system/local/server.conf"
  old_stanzas = CernerSplunk::Conf::Reader.new(path).read if File.exist?(path)
  old_id = (old_stanzas['shclustering'] || {})['id'] if old_stanzas

  server_stanzas['shclustering'] = settings
  server_stanzas['shclustering']['pass4SymmKey'] = CernerSplunk::ConfTemplate.compose encrypt_password, CernerSplunk::ConfTemplate::Value.constant(value: pass) if pass
  server_stanzas['shclustering']['conf_deploy_fetch_url'] = deployer_uri
  server_stanzas['shclustering']['disabled'] = 0
  server_stanzas['shclustering']['mgmt_uri'] = "https://#{node['splunk']['mgmt_host']}:8089"
  server_stanzas['shclustering']['id'] = old_id if old_id
end

# License Configuration
license_uri =
  case node['splunk']['node_type']
  when :license_server
    'self'
  when :cluster_master, :cluster_slave, :server, :search_head, :shc_search_head, :shc_captain, :shc_deployer
    if node['splunk']['free_license']
      'self'
    else
      CernerSplunk.my_cluster_data(node)['license_uri'] || 'self'
    end
  when :forwarder
    if node['splunk']['package']['base_name'] == 'splunk' && node['splunk']['heavy_forwarder']['use_license_uri']
      CernerSplunk.my_cluster_data(node)['license_uri'] || 'self'
    else
      'self'
    end
  end

license_group =
  case node['splunk']['node_type']
  when :license_server
    'Enterprise'
  when :cluster_master, :cluster_slave, :shc_search_head, :shc_captain, :shc_deployer
    if license_uri == 'self'
      'Trial'
    else
      'Enterprise'
    end
  when :forwarder
    'Forwarder'
  when :search_head
    if license_uri == 'self'
      'Trial'
    else
      'Forwarder'
    end
  when :server
    if node['splunk']['free_license']
      'Free'
    elsif license_uri == 'self'
      'Trial'
    else
      'Enterprise'
    end
  end

if license_uri == 'self'
  %w[forwarder free enterprise download-trial].each do |group|
    server_stanzas["lmpool:auto_generated_pool_#{group}"] = {
      'description' => "auto_generated_pool_#{group}",
      'quota' => 'MAX',
      'slaves' => '*',
      'stack_id' => group
    }
  end
end

license_pools = CernerSplunk::DataBag.load(node['splunk']['config']['license-pool'], secret: node['splunk']['data_bag_secret'])

if node['splunk']['node_type'] == :license_server && !license_pools.nil?
  auto_generated_pool_size = CernerSplunk.convert_to_bytes license_pools['auto_generated_pool_size']
  server_stanzas['lmpool:auto_generated_pool_enterprise']['quota'] = auto_generated_pool_size
  allotted_pool_size = 0

  license_pools['pools'].each do |pool, pool_config|
    pool_max_size = CernerSplunk.convert_to_bytes pool_config['size']
    server_stanzas["lmpool:#{pool}"] = {
      'description' => pool,
      'quota' => pool_max_size,
      'slaves' => pool_config['GUIDs'].join(','),
      'stack_id' => 'enterprise'
    }
    allotted_pool_size += pool_max_size
  end
  node.run_state['cerner_splunk']['total_allotted_pool_size'] = allotted_pool_size + auto_generated_pool_size
end

server_stanzas['license'] = {
  'master_uri' => license_uri,
  'active_group' => license_group
}

splunk_template 'system/server.conf' do
  stanzas server_stanzas
  notifies :touch, 'file[splunk-marker]', :immediately
end
