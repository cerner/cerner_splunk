# coding: UTF-8
#
# Cookbook Name:: cerner_splunk
# Recipe:: _configure_indexes
#
# Configures the indexes.conf file.

indexbag = CernerSplunk.my_cluster_data(node)['indexes']
bag = CernerSplunk::DataBag.load(indexbag)

unless bag
  Chef::Log.info 'No indexes data bag configured.'
  return
end

config = bag['config'] || {}
flags = bag['flags'] || {}

is_master = node['splunk']['node_type'] == :cluster_master

index_stanzas = config.inject({}) do |result, (stanza, index_config)|
  index_flags = flags[stanza] || {}
  hash = {}.merge! index_config

  stanza_type =
    case stanza
    when 'default'
      :default
    when /^volume:.*/
      :volume
    when /^provider-family:.*/
      :provider_family
    when /^.*:.*/
      :unknown
    else
      :index
    end

  if stanza_type == :index
    unless index_flags['noGeneratePaths']
      volume = hash.delete('_volume')
      base_path = volume ? "volume:#{volume}" : '$SPLUNK_DB'
      dir_name = hash.key?('_directory_name') ? hash.delete('_directory_name') : stanza
      hash['coldPath'] = "#{base_path}/#{dir_name}/colddb" unless hash['coldPath']
      hash['homePath'] = "#{base_path}/#{dir_name}/db" unless hash['homePath']
      hash['thawedPath'] = "$SPLUNK_DB/#{dir_name}/thaweddb" unless hash['thawedPath']
      hash['tstatsHomePath'] = "#{base_path}/#{dir_name}/datamodel_summary" if volume && !hash['tstatsHomePath']
    end
    if is_master && !index_flags['noRepFactor']
      hash['repFactor'] = 'auto' unless hash['repFactor']
    end
  end

  result[stanza] = hash
  result
end

if is_master && index_stanzas['_introspection'].nil?
  index_stanzas['_introspection'] = { 'repFactor' => 'auto' }
end

path = is_master ? 'master-apps/_cluster/indexes.conf' : 'system/indexes.conf'

splunk_template path do
  stanzas index_stanzas
  notifies :touch, 'file[splunk-marker]', :immediately unless is_master
  notifies :run, 'execute[apply-cluster-bundle]' if is_master
end
