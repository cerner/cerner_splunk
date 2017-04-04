
# frozen_string_literal: true

#
# Cookbook Name:: cerner_splunk
# File Name:: authentication.rb

require_relative 'databag'

module CernerSplunk
  ASSUMPTIONS =
    {
      'LDAP_strategies' => 'LDAP',
      'cacheTiming' => 'Scripted',
      'scriptPath' => 'Scripted',
      'scriptSearchFilters' => 'Scripted',
      'passwordHashAlgorithm' => 'Splunk'
    }.freeze

  # Module contains functions to configure authentication in a Splunk system
  module Authentication
    def self.configure_authentication(node, hash) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, MethodLength
      hash = hash.clone
      auth_stanzas = { 'authentication' => hash }
      raise "authSettings is managed by chef. Don't set it yourself!" if hash.key?('authSettings')

      unless hash['authType']
        guesses = ASSUMPTIONS.each_with_object([]) do |(key, type), result|
          result << type if hash.key?(key) && !result.include?(type)
        end

        hash['authType'] =
          case guesses.length
          when 0
            'Splunk'
          when 1
            guesses.first
          else
            raise "Unable to determine authType! Guesses include #{guesses.join(',')}"
          end
      end

      ASSUMPTIONS.each do |key, type|
        if hash['authType'] != type && hash.key?(key)
          raise "#{key} is only supported with #{type}. authType = #{hash['authType']}"
        end
      end

      default_coords = CernerSplunk::DataBag.to_a node['splunk']['config']['authentication']

      case hash['authType']
      when 'Splunk'
      # Nothing special to do here.
      when 'Scripted'
        script = {
          'scriptPath' => hash.delete('scriptPath')
        }
        raise 'scriptPath required for Scripted authentication' unless script['scriptPath']
        search_filters = hash.delete('scriptSearchFilters')
        script['scriptSearchFilters'] = search_filters if search_filters
        hash['authSettings'] = 'script'
        auth_stanzas['script'] = script
        cache_timing = hash.delete('cacheTiming')
        if cache_timing
          raise "Unknown type for cacheTiming: #{cacheTiming.class}" unless cache_timing.is_a?(Hash)
          auth_stanzas['cacheTiming'] = cache_timing
        end
      when 'LDAP'
        strategies = hash.delete('LDAP_strategies')
        raise 'LDAP_strategies required for LDAP authentication' unless strategies
        strategies = [strategies] unless strategies.is_a? Array
        strategies = strategies.collect do |strategy|
          hash =
            case strategy
            when String
              CernerSplunk::DataBag.load strategy, default: default_coords
            when Hash
              temp = strategy.clone
              bag_coords = temp.delete('bag')
              bag = CernerSplunk::DataBag.load bag_coords, default: default_coords
              case bag
              when nil
                temp
              when Hash, Chef::DataBagItem
                # ew. Hm... I wonder if we can have the library guarantee a Hash...
                bag.clone.merge temp
              else
                raise "Unexpected type for LDAP Strategy #{bag.class} at #{bag_coords}"
              end
            else
              raise "Unexpected type for LDAP Strategy #{strategy.class}"
            end
          raise "Unexpected property 'bag'" if hash.delete('bag')

          %w[userBaseDN groupBaseDN].each do |x|
            hash[x] = hash[x].join(';') if hash[x].is_a?(Array)
          end

          hash['roleMap'] = (hash['roleMap'] || {}).each_with_object({}) do |(k, v), h|
            h[k] = v.is_a?(Array) ? v.join(';') : v.to_s
          end

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
          strategy_name = strategy.delete('strategy_name')
          strategy_name ||= "#{strategy['host']}:#{strategy['port'] || 389}"

          raise "Duplicate Strategy declaration of #{strategy_name}" if auth_stanzas[strategy_name]

          auth_stanzas[strategy_name] = strategy
          auth_stanzas["roleMap_#{strategy_name}"] = strategy.delete('roleMap')

          raise "Resolved Role Map for Strategy Name #{strategy_name} is empty!!!" if auth_stanzas["roleMap_#{strategy_name}"].empty?
          strategy_name
        end.join(',')
      else
        raise "Unsupported Auth type '#{hash['authType']}'"
      end
      auth_stanzas
    end
  end
end
