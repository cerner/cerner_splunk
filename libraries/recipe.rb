
# frozen_string_literal: true

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

  NODE_TYPE ||= lambda do |symbol|
    throw 'Symbol should not be nil' unless symbol
    throw "Cannot set type '#{symbol}', already set '#{node.default['splunk']['node_type']}'" if node.default['splunk']['node_type']
    if node['splunk']['free_license']
      throw "Cannot use the Splunk #{symbol} recipe with the free license" unless %i[forwarder server].include? symbol
    end
    node.default['splunk']['node_type'] = symbol.to_sym
  end

  # TODO: Rename these methods

  # Returns the key identifing the current cluster
  def self.my_cluster_key(node)
    node['splunk']['config']['clusters'].first
  end

  # Returns the data bag item corresponding to my cluster (not other clusters)
  def self.my_cluster_data(node)
    @my_cluster_data ||= CernerSplunk::DataBag.load(node['splunk']['config']['clusters'].first)
  end

  # Returns a single (Array) pair of my cluster key with the corresponding data bag
  def self.my_cluster(node)
    [my_cluster_key(node), my_cluster_data(node)]
  end

  # Returns the array of all data bag items for all clusters
  def self.all_clusters_data(node)
    unless @all_cluster_data
      _head, *others = node['splunk']['config']['clusters']
      @all_cluster_data = [my_cluster_data(node)] + (others.collect { |x| CernerSplunk::DataBag.load(x) })
    end
    @all_cluster_data
  end

  # Returns an array of (array) pairs of the cluster key with the corresponding data bag item
  def self.all_clusters(node)
    node['splunk']['config']['clusters'].zip all_clusters_data(node)
  end

  # Order of keys to use when searching bags by context.
  def self.keys(node)
    order = []
    order << node['splunk']['config']['host']
    order << node.name unless order.include? node.name
    order << node['fqdn'] unless order.include? node['fqdn']
    order << node['splunk']['node_type'].to_s
    order << ''
    order
  end

  # Convert Splunk artifact name into installation type
  def self.package_type(package_name)
    case package_name
    when 'splunk', :splunk then 'splunk'
    when 'splunkforwarder', :splunkforwarder, :universal_forwarder then 'universal_forwarder'
    end
  end

  # Returns filepath to splunk bin based on platform family
  def self.splunk_command(node)
    # Chef::Log.warn(node['splunk']['home'])
    filepath = "#{node['splunk']['home']}/bin/splunk"
    # Chef::Log.warn(filepath)

    return %("#{filepath.tr('/', '\\')}") if node['platform_family'] == 'windows'

    filepath
  end

  # Returns the opposite package name of the currently set package base name
  def self.opposite_package_name(package_base_name)
    package_base_name == 'splunk' ? 'splunkforwarder' : 'splunk'
  end

  # Returns the installed package name based on platform and package base name.
  # Written because Windows is dumb
  def self.installed_package_name(platform_family, package_base_name)
    return package_base_name unless platform_family == 'windows'

    # Windows package names
    return 'Splunk Enterprise' if package_base_name == 'splunk'
    'UniversalForwarder'
  end

  # Returns Boolean for whether a separate Splunk artifact is already installed.
  def self.separate_splunk_installed?(node)
    opposite_package_name = opposite_package_name(node['splunk']['package']['base_name'])
    old_package_type = package_type(opposite_package_name).to_sym
    Dir.exist?(CernerSplunk::PathHelpers.default_install_dirs.dig(old_package_type, node['os'].to_sym))
  end

  # Returns the Splunk service name based on platform and package name
  def self.splunk_service_name(platform_family, package_base_name)
    if platform_family == 'windows'
      return 'SplunkForwarder' if package_base_name == 'splunkforwarder'
      return 'Splunkd' if package_base_name == 'splunk'
    end

    'splunk'
  end

  # Validates that the splunk.secret file either does not exist or has the same value that's currently configured.
  # Fails the chef run if those constraints are not met.
  def self.validate_secret_file(secret_file_path, configured_secret)
    return unless ::File.exist?(secret_file_path)
    existing_secret = ::File.open(secret_file_path, 'r') { |file| file.readline.chomp }
    raise 'The splunk.secret file already exists with a different value. Modification of that file is not currently supported.' if existing_secret != configured_secret
  end
end
