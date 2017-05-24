
# frozen_string_literal: true

#
# Cookbook Name:: cerner_splunk
# File Name:: authentication.rb

require_relative 'databag'

module CernerSplunk
  # Module contains functions to configure authentication in a Splunk system
  module Authentication
    def self.determine_auth_type(settings)
      config_mapping = {
        'LDAP_strategies' => 'LDAP',
        'cacheTiming' => 'Scripted',
        'scriptPath' => 'Scripted',
        'scriptSearchFilters' => 'Scripted',
        'passwordHashAlgorithm' => 'Splunk'
      }.freeze

      probable_types = config_mapping.values_at(*settings.keys)
      raise "Conflicting authentication types were derived from the config: #{probable_types.join(',')}" if probable_types.length > 1

      settings['authType'] || probable_types.first || 'Splunk'
    end

    def self.configure_authentication(node, hash) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, MethodLength
      hash = hash.clone
      auth_stanzas = { 'authentication' => hash }
      raise "authSettings is managed by Chef. Don't set it yourself!" if hash.key?('authSettings')

      hash['authType'] = determine_auth_type(hash)

      default_coords = CernerSplunk::DataBag.to_a node['splunk']['config']['authentication']

      case hash['authType']
      when 'Splunk' then nil # Nothing special to do here.
      when 'Scripted'
        raise 'scriptPath required for Scripted authentication' unless hash['scriptPath']
        script = { 'scriptPath' => hash.delete('scriptPath') }
        script['scriptSearchFilters'] = hash.delete 'scriptSearchFilters' if hash.key? 'scriptSearchFilters'
        auth_stanzas['script'] = script
        hash['authSettings'] = 'script'

        if hash.key? 'cacheTiming'
          raise "Unknown type for cacheTiming: #{cacheTiming.class}" unless hash['cacheTiming'].is_a?(Hash)
          auth_stanzas['cacheTiming'] = hash.delete('cacheTiming')
        end

      when 'LDAP'
        raise 'LDAP_strategies required for LDAP authentication' unless hash['LDAP_strategies']
        strategies = [hash.delete('LDAP_strategies')] unless hash['LDAP_strategies'].is_a? Array
        strategies = strategies.collect do |strategy|
          hash =
            case strategy
            when String then CernerSplunk::DataBag.load strategy, default: default_coords
            when Hash
              temp = strategy.clone
              bag_coords = temp.delete('bag')
              bag = CernerSplunk::DataBag.load bag_coords, default: default_coords
              case bag
              when nil then temp
              # ew. Hm... I wonder if we can have the library guarantee a Hash...
              when Hash, Chef::DataBagItem then bag.clone.merge temp # ~FC086 False Positive
              else raise "Unexpected type for LDAP Strategy #{bag.class} at #{bag_coords}"
              end
            else raise "Unexpected type for LDAP Strategy #{strategy.class}"
            end

          raise "Unexpected property 'bag'" if hash.delete('bag')

          %w[userBaseDN groupBaseDN].each do |x|
            hash[x] = hash[x].join(';') if hash[x].is_a?(Array)
          end

          hash['roleMap'] = (hash['roleMap'] || {}).collect { |k, v| [k, v.is_a?(Array) ? v.join(';') : v.to_s] }.to_h

          if hash['bindDNpassword']
            vault_password = CernerSplunk::ConfigProcs::Value.vault coordinate: hash['bindDNpassword'], default_coords: default_coords
            encrypt = CernerSplunk::ConfigProcs::Transform.splunk_encrypt node: node
            hash['bindDNpassword'] = CernerSplunk::ConfigProcs.compose encrypt, vault_password
          end

          # Verify Attributes
          %w[host userBaseDN userNameAttribute realNameAttribute groupBaseDN groupNameAttribute groupMemberAttribute].each do |x|
            raise "#{x} is required to be set on an LDAP Strategy" if hash[x].nil? || hash[x].strip.empty?
          end
          hash
        end

        raise 'LDAP_strategies required for LDAP authentication' if strategies.empty?

        auth_stanzas['authentication']['authSettings'] = strategies.collect do |strategy|
          strategy_name = strategy.delete('strategy_name') || "#{strategy['host']}:#{strategy['port'] || 389}"

          raise "Duplicate Strategy declaration of #{strategy_name}" if auth_stanzas[strategy_name]
          raise "Resolved Role Map for Strategy Name #{strategy_name} is empty!!!" if strategy['roleMap'].empty?

          auth_stanzas[strategy_name] = strategy
          auth_stanzas["roleMap_#{strategy_name}"] = strategy.delete('roleMap')

          strategy_name
        end.join(',')
      else raise "Unsupported Auth type '#{hash['authType']}'"
      end
      auth_stanzas
    end
  end
end
