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
      hash['coldPath'] = "$SPLUNK_DB/#{stanza}/colddb" unless hash['coldPath']
      hash['homePath'] = "$SPLUNK_DB/#{stanza}/db" unless hash['homePath']
      hash['thawedPath'] = "$SPLUNK_DB/#{stanza}/thaweddb" unless hash['thawedPath']
    end
    if is_master && !index_flags['noRepFactor']
      hash['repFactor'] = 'auto' unless hash['repFactor']
    end
  end

  result[stanza] = hash
  result
end

path = is_master ? 'master-apps/_cluster/indexes.conf' : 'system/indexes.conf'

splunk_template path do
  stanzas index_stanzas
  notifies :restart, 'service[splunk]' unless is_master
  notifies :run, 'execute[apply-cluster-bundle]' if is_master
end
