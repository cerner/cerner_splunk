# coding: UTF-8

# Cookbook Name:: cerner_splunk
# File Name:: splunk_template.rb
# HWR for configuring Splunk.

require 'chef/resource/template'
require 'chef/provider/template'
require 'chef/mixin/securable'
require_relative 'lwrp'
require_relative 'passive_sensitive'

class Chef
  class Resource
    # Heavyweight Resource for Splunk conf files
    class SplunkTemplate < Chef::Resource::Template
      include Chef::Mixin::Securable
      extend CernerSplunk::LWRP::DelayableAttribute unless defined? delayable_attribute

      use_provider_resolver = defined?(Chef::ProviderResolver) == 'constant' && Chef::ProviderResolver.class == Class

      provides :splunk_template, (use_provider_resolver ? {} : { on_platforms: :all })

      def initialize(name, run_context = nil)
        super

        # If there's no run_context, there's nothing we can do here
        # assuming this is a sensitive resource: https://github.com/chef/chef/pull/5668
        return if run_context.nil?

        @variables = nil
        @fail_unknown = true
        backup false
        cookbook 'cerner_splunk'
        source 'generic.conf.erb'
        user node['splunk']['user']
        group node['splunk']['group']
        mode '0600'
        provider Chef::Provider::Template
        # atomic_update in this instance causes issues on windows similar to
        # https://tickets.opscode.com/browse/CHEF-4625
        # However, atomic_update from a chef provided template resource
        # works on the same node that this fails.
        atomic_update false if platform_family?('windows')

        # If resource name is unambiguous, default values
        case name
        when %r{^system/(.+\.conf)$}
          @path = "etc/system/local/#{Regexp.last_match[1]}"
        when %r{^shcluster/([^/]+)/(.+\.conf)$}
          @path = "etc/shcluster/apps/#{Regexp.last_match[1]}/local/#{Regexp.last_match[2]}"
        when %r{^((?:master-)?app)s?/([^/]+)/(.+\.conf)$}
          @path = "etc/#{Regexp.last_match[1]}s/#{Regexp.last_match[2]}/local/#{Regexp.last_match[3]}"
        end
      end

      delayable_attribute :stanzas, default: {}, kind_of: Hash

      def variables(args = nil)
        val = set_or_return(:variables, args, kind_of: [Hash])
        if args || val
          val
        else
          { stanzas: stanzas }
        end
      end

      def fail_unknown(args = nil)
        set_or_return(:fail_unknown, args, kind_of: [TrueClass, FalseClass])
      end

      def after_created
        @path = "#{node['splunk']['home']}/#{@path}"

        config_file = ::File.basename(@path)
        return if KNOWN_CONFIG_FILES.include? config_file
        message = "#{config_file} is not known to this resource. Check spelling or submit a pull request."
        Chef::Log.warn message unless fail_unknown
        fail Exceptions::ValidationFailed, "#{message}\nKnown files are:\n\t#{KNOWN_CONFIG_FILES.join("\n\t")}" if fail_unknown
      end

      KNOWN_CONFIG_FILES = %w[
        alert_actions.conf
        authentication.conf
        authorize.conf
        indexes.conf
        inputs.conf
        outputs.conf
        server.conf
        user-prefs.conf
        ui-prefs.conf
      ].freeze
    end
  end
end
