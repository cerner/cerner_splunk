# coding: UTF-8
#
# Cookbook Name:: cerner_splunk
# File Name:: recipe.rb
#
# This recipe contains utilities to help with Splunk Recipes.

require_relative 'databag'

# Module for the cookbook
module CernerSplunk
  # This lambda is used to ensure that only one of a set of recipes is on the run_list
  # Call it on each recipe with 'instance_exec :whatever_type, &CernerSplunk::NODE_TYPE'
  NODE_TYPE = lambda do |symbol|
    throw 'Symbol should not be nil' unless symbol
    throw "Cannot set type '#{symbol}', already set '#{node.default[:splunk][:node_type]}'" if node.default[:splunk][:node_type]
    if node[:splunk][:free_license]
      throw "Cannot use the Splunk #{symbol} recipe with the free license" unless [:forwarder, :server].include? symbol
    end
    node.default[:splunk][:node_type] = symbol.to_sym
  end

  # Returns the key identifing the current cluster
  def self.my_cluster_key(node)
    node[:splunk][:config][:clusters].first
  end

  # Returns the data bag item corresponding to my cluster (not other clusters)
  def self.my_cluster_data(node)
    @my_cluster_data ||= CernerSplunk::DataBag.load(node[:splunk][:config][:clusters].first)
  end

  # Returns a single (Array) pair of my cluster key with the corresponding data bag
  def self.my_cluster(node)
    [my_cluster_key(node), my_cluster_data(node)]
  end

  # Returns the array of all data bag items for all clusters
  def self.all_clusters_data(node)
    unless @all_cluster_data
      _head, *others = node[:splunk][:config][:clusters]
      @all_cluster_data = [my_cluster_data(node)] + others.collect { |x| CernerSplunk::DataBag.load(x) }
    end
    @all_cluster_data
  end

  # Returns an array of (array) pairs of the cluster key with the corresponding data bag item
  def self.all_clusters(node)
    node[:splunk][:config][:clusters].zip all_clusters_data(node)
  end

  # Order of keys to use when searching bags by context.
  def self.keys(node)
    order = []
    order << node[:splunk][:config][:host]
    order << node.name unless order.include? node.name
    order << node[:fqdn] unless order.include? node[:fqdn]
    order << node[:splunk][:node_type].to_s
    order << ''
    order
  end
end
