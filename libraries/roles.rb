# coding: UTF-8

# Cookbook Name:: cerner_splunk
# File Name:: roles.rb

require_relative 'databag'

module CernerSplunk
  # Module contains functions to configure roles in a Splunk system
  module Roles
    def self.configure_roles(hash) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, MethodLength
      user_prefs = {}
      authorize = {}

      hash.each do |stanza, values|
        pref_entries, auth_entries = values.inject([{}, {}]) do |result, (key, value)|
          prefs = result[0]
          auth = result[1]

          case key
          when 'tz', 'showWhatsNew'
            prefs[key] = value
          when 'app'
            prefs['default_namespace'] = value
          when 'capabilities'
            value.each do |cap|
              if cap.start_with? '!'
                cap[0] = ''
                auth[cap] = 'disabled'
              else
                auth[cap] = 'enabled'
              end
            end
          else
            auth[key] =
              if value.is_a? Array
                value.join(';')
              else
                value
              end
          end
          result
        end

        unless pref_entries.empty?
          pref_stanza = stanza == 'default' ? 'general_default' : "role_#{stanza}"
          user_prefs[pref_stanza] = pref_entries
        end

        if stanza == 'default'
          authorize['default'] = auth_entries unless auth_entries.empty?
        else
          authorize["role_#{stanza}"] = auth_entries
        end
      end
      [authorize, user_prefs]
    end
  end
end
