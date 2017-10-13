# coding: UTF-8

# Cookbook Name:: cerner_splunk
# File Name:: alerts.rb

require_relative 'databag'

module CernerSplunk
  # Module contains functions to configure alerts in a Splunk system
  module Alerts
    def self.configure_alerts(node, hash)
      hash = hash.clone
      default_coords = CernerSplunk::DataBag.to_a node['splunk']['config']['alerts']
      bag = CernerSplunk::DataBag.load hash.delete('bag'), default: default_coords, secret: node['splunk']['data_bag_secret']

      alert_stanzas =
        if bag
          bag.to_hash.merge(hash) do |_key, default_hash, override_hash|
            default_hash.merge(override_hash)
          end
        else
          hash
        end

      fail 'Unexpected property \'bag\'' if alert_stanzas.delete('bag')

      email_settings = alert_stanzas['email'] || {}

      if email_settings['auth_password']
        password = CernerSplunk::DataBag.load email_settings['auth_password'], default: default_coords, secret: node['splunk']['data_bag_secret']
        fail 'Password must be a String' unless password.is_a?(String)
        email_settings['auth_password'] = password
      end
      alert_stanzas
    end
  end
end
