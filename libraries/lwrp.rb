
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
    def self.convert_monitors(node_monitors, default_index = nil, base = {})
      monitors = node_monitors.dup || []
      monitor_stanzas = monitors.map do |monitor|
        monitor.each_key(&:to_s)
        type = monitor.delete('type') || 'monitor'
        path = monitor.delete('path')

        base_hash = default_index ? { 'index' => default_index } : {}
        ["#{type}://#{path}", base_hash.merge(monitor)]
      end.to_h

      base.merge(monitor_stanzas)
    end
  end
end
