# coding: UTF-8
#
# Cookbook Name:: cerner_splunk
# Recipe:: _configure_server
#
# Configures the system server.conf file

server_stanzas = {
  'general' => {
    'serverName' => node[:splunk][:config][:host]
  },
  'sslConfig' => {}
}

SLAVE_ONLY_CONFIGS = %w(
  max_replication_errors
  register_replication_address
  register_forwarder_address
  register_search_address
  heartbeat_period
  enableS2SHeartbeat
)

MASTER_ONLY_CONFIGS = %w(
  replication_factor
  search_factor
  heartbeat_timeout
  restart_timeout
  quiet_period
  generation_poll_interval
  searchable_targets
  target_wait_time
  commit_retry_time
)

case node[:splunk][:node_type]
when :search_head, :server
  clusters = CernerSplunk.all_clusters(node).collect do |(cluster, bag)|
    stanza = "clustermaster:#{cluster}"
    master_uri = bag['master_uri'] || ''
    settings = bag['settings'] || {}
    pass = settings['pass4SymmKey'] || ''

    next if master_uri.empty?

    server_stanzas[stanza] = {}
    server_stanzas[stanza]['master_uri'] = master_uri
    server_stanzas[stanza]['pass4SymmKey'] = pass unless pass.empty?
    stanza
  end

  clusters.reject!(&:nil?)

  if clusters.any?
    server_stanzas['clustering'] = {}
    server_stanzas['clustering']['mode'] = 'searchhead'
    server_stanzas['clustering']['master_uri'] = clusters.join(',')
  end
when :cluster_master
  bag = CernerSplunk.my_cluster_data(node)
  settings = (bag['settings'] || {}).delete_if do |k, _|
    k.start_with?('_cerner_splunk') || SLAVE_ONLY_CONFIGS.include?(k)
  end

  server_stanzas['clustering'] = settings
  server_stanzas['clustering']['mode'] = 'master'
when :cluster_slave
  cluster, bag = CernerSplunk.my_cluster(node)
  master_uri = bag['master_uri'] || ''
  replication_ports = bag['replication_ports'] || {}
  settings = (bag['settings'] || {}).delete_if do |k, _|
    k.start_with?('_cerner_splunk') || MASTER_ONLY_CONFIGS.include?(k)
  end

  throw "Missing master uri for cluster '#{cluster}'" if master_uri.empty?
  throw "Missing replication port configuration for cluster '#{cluster}'" if replication_ports.empty?

  server_stanzas['clustering'] = settings
  server_stanzas['clustering']['mode'] = 'slave'
  server_stanzas['clustering']['master_uri'] = master_uri

  replication_ports.each do |port, port_settings|
    ssl = port_settings['_cerner_splunk_ssl'] == true
    stanza = ssl ? "replication_port-ssl://#{port}" : "replication_port://#{port}"
    server_stanzas[stanza] = port_settings.delete_if do |k, _|
      k.start_with? '_cerner_splunk'
    end
  end
end

# License Configuration
license_uri =
  case node[:splunk][:node_type]
  when :forwarder, :license_server
    'self'
  when :cluster_master, :cluster_slave, :search_head, :server
    if node[:splunk][:free_license]
      'self'
    else
      CernerSplunk.my_cluster_data(node)['license_uri'] || 'self'
    end
  end

license_group =
  case node[:splunk][:node_type]
  when :license_server, :cluster_master, :cluster_slave
    'Enterprise'
  when :forwarder
    'Forwarder'
  when :search_head
    if license_uri == 'self'
      'Enterprise'
    else
      'Forwarder'
    end
  when :server
    if node[:splunk][:free_license]
      'Free'
    else
      'Enterprise'
    end
  end

%w(forwarder free enterprise download-trial).each do |group|
  server_stanzas["lmpool:auto_generated_pool_#{group}"] = {
    'description' => "auto_generated_pool_#{group}",
    'quota' => 'MAX',
    'slaves' => '*',
    'stack_id' => group
  }
end if license_uri == 'self'

server_stanzas['license'] = {
  'master_uri' => license_uri,
  'active_group' => license_group
}

splunk_template 'system/server.conf' do
  stanzas do
    old_stanzas = CernerSplunk::Conf::Reader.new("#{node[:splunk][:home]}/etc/system/local/server.conf").read

    old_stanzas.each do |key, value|
      case key
      when 'general'
        server_stanzas['general']['guid'] = value['guid'] if value['guid']
      when 'sslConfig'
        server_stanzas['sslConfig']['sslKeysfilePassword'] = value['sslKeysfilePassword']
      end
    end

    server_stanzas
  end
  notifies :restart, 'service[splunk]'
end
