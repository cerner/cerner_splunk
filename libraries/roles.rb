
# frozen_string_literal: true

#
# Cookbook Name:: cerner_splunk
# File Name:: roles.rb

require_relative 'databag'

module CernerSplunk
  # Module contains functions to configure roles in a Splunk system
  module Roles
    def self.configure_roles(config)
      user_prefs = {}
      authorize = {}

      config.each do |stanza, props|
        pref_entries, auth_entries = props.partition { |key, _| %w[tz app].include?(key) }.map(&:to_h)

        role_stanza = stanza != 'default' && "role_#{stanza}"

        # Set the role user prefs -- unless it's empty, then we can leave it out
        user_prefs[role_stanza || 'general_default'] = prepare_preferences(pref_entries) unless pref_entries.empty?
        # Always create authorization config for a role, even if empty.
        # Default doesn't apply to this, but we don't care if it is empty, so leave out the extra complexity.
        authorize[role_stanza || 'default'] = prepare_authorizations(auth_entries)
      end
      [authorize, user_prefs]
    end

    def self.prepare_preferences(preferences)
      preferences['default_namespace'] = preferences.delete('app') if preferences.key? 'app'
      preferences
    end

    def self.prepare_authorizations(authorizations)
      (authorizations.delete('capabilities') || []).each do |capability|
        if capability.start_with? '!'
          authorizations[capability[1..-1]] = 'disabled'
        else
          authorizations[capability] = 'enabled'
        end
      end

      authorizations.map { |key, value| [key, value.is_a?(Array) ? value.join(';') : value] }.to_h
    end
  end
end
