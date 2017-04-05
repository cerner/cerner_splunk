
# frozen_string_literal: true

#
# Cookbook Name:: cerner_splunk
# File Name:: lwrp.rb
#
# This file contains modules that can be used to extend the LWRP DSL.
# Most will follow the pattern of in order to use, include at the top of your resource / provider:
#
# extend CernerSplunk::LWRP::(module) unless defined? (method name)

require_relative 'databag'
require_relative 'recipe'

module CernerSplunk
  # Methods involved with augmenting the LWRP syntax / writing recipies
  module LWRP
    # Change a list of monitors to a hash of stanzas for writing to a config file
    def self.convert_monitors(node, monitors, default_index = nil, base = {})
      all_stanzas = base.merge monitors.map do |monitor|
        monitor.each_key(&:to_s)
        type = monitor.delete('type') || 'monitor'
        path = monitor.delete('path')

        base_hash = default_index ? { 'index' => default_index } : {}
        ["#{type}://#{path}", base_hash.merge(monitor)]
      end.to_h

      validate_indexes(node, all_stanzas)
    end

    # Validate the indexes to which data is being forwarded to
    def self.validate_indexes(node, monitors) # rubocop:disable CyclomaticComplexity
      index_error = []
      input_regex = /^(?:monitor|tcp|batch|udp|fifo|script|fschange)/

      indexes = monitors.select { |key, _| input_regex.match(key) }.collect { |_, v| v['index'] || node['splunk']['config']['assumed_index'] }.uniq

      CernerSplunk.all_clusters(node).each do |(cluster, data_bag)|
        bag = CernerSplunk::DataBag.load(data_bag['indexes'], handle_load_failure: true)

        # Check if the indexes is not listed in the cluster data bag
        unless bag
          Chef::Log.warn "The indexes in the cluster '#{cluster}' is not defined or could not be loaded, therefore index checks could not be performed"
          next
        end

        indexes.each do |index|
          # Check if the index is not defined in the data bag
          unless bag['config'].key?(index)
            index_error << "Index '#{index}' is not defined by chef in cluster '#{cluster}'"
            next
          end

          %w[isReadOnly disabled deleted].each do |state|
            if %w[1 true].include?(bag['config'][index][state].to_s)
              index_error << "Cannot forward data to index '#{index}' in the cluster '#{cluster}', because the index is marked as '#{state}'"
            end
          end
        end
      end

      unless index_error.empty?
        index_error_msg = "Data cannot be forwarded to respective index(es) due to the following reason(s):\n#{index_error.join("\n")}"
        raise index_error_msg if node['splunk']['flags']['index_checks_fail']
        Chef::Log.warn index_error_msg
      end

      monitors
    end
  end
end
