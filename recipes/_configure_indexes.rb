
# frozen_string_literal: true

#
# Cookbook Name:: cerner_splunk
# Recipe:: _configure_indexes
#
# Configures the indexes.conf file.

bag = CernerSplunk::DataBag.load(CernerSplunk.my_cluster_data(node)['indexes'])

unless bag
  Chef::Log.info 'No indexes data bag configured.'
  return
end

config = bag['config'] || {}
flags = bag['flags'] || {}

is_master = node['splunk']['node_type'] == :cluster_master

index_stanzas = config.each_with_object({}) do |(stanza, index_config), result|
  index_flags = flags[stanza] || {}
  hash = {}.merge! index_config

  stanza_type =
    case stanza
    when 'default' then :default
    when /^volume:.*/ then :volume
    when /^provider-family:.*/ then :provider_family
    when /^.*:.*/ then :unknown
    else :index
    end

  # Make sure we remove meta properties from the hash first
  daily_mb = hash.delete('_maxDailyDataSizeMB')
  padding_pct = hash.delete('_dataSizePaddingPercent')

  if %i[index default].include?(stanza_type) && daily_mb && !hash.key?('maxTotalDataSizeMB')
    settings = CernerSplunk.my_cluster_data(node).fetch('settings', {})
    replication_factor = settings['replication_factor'] || 1
    indexer_count = settings['_cerner_splunk_indexer_count'] || 1

    default_config = config.fetch('default', {})

    # If the frozen time isn't specified, splunk defaults to 6 years
    frozen_time_in_secs = hash['frozenTimePeriodInSecs'] || default_config['frozenTimePeriodInSecs'] || 188_697_600
    frozen_time_in_days = frozen_time_in_secs / 86_400

    padding_pct ||= default_config['_dataSizePaddingPercent']
    padding = padding_pct.nil? ? 1.1 : 1 + (padding_pct / 100.0)

    hash['maxTotalDataSizeMB'] = (daily_mb * padding * frozen_time_in_days * replication_factor).to_i / indexer_count
  end

  if stanza_type == :index
    unless index_flags['noGeneratePaths']
      volume = hash.delete('_volume')
      base_path = volume ? "volume:#{volume}" : '$SPLUNK_DB'
      dir_name = hash.delete('_directory_name') || stanza
      hash['coldPath'] ||= "#{base_path}/#{dir_name}/colddb"
      hash['homePath'] ||= "#{base_path}/#{dir_name}/db"
      hash['thawedPath'] ||= "$SPLUNK_DB/#{dir_name}/thaweddb"
      hash['tstatsHomePath'] ||= "#{base_path}/#{dir_name}/datamodel_summary" if volume
    end

    hash['repFactor'] ||= 'auto' if is_master && !index_flags['noRepFactor']
  end

  result[stanza] = hash
end

if is_master && index_stanzas['_introspection'].nil?
  index_stanzas['_introspection'] = { 'repFactor' => 'auto' }
end

path = is_master ? 'master-apps/_cluster/indexes.conf' : 'system/indexes.conf'

splunk_conf path do
  config index_stanzas
  action :configure
  notifies :run, 'execute[apply-cluster-bundle]' if is_master
  notifies :desired_restart, "splunk_service[#{node['splunk']['package']['type']}]", :immediately
end
