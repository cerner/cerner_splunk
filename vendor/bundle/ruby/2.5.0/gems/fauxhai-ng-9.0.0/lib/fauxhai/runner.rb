require "ohai" unless defined?(Ohai::System)
require "ohai/plugins/chef"

module Fauxhai
  class Runner
    def initialize(args)
      @system = Ohai::System.new
      @system.all_plugins

      case @system.data["platform"]
      when "windows", :windows
        require_relative "runner/windows"
        singleton_class.send :include, ::Fauxhai::Runner::Windows
      else
        require_relative "runner/default"
        singleton_class.send :include, ::Fauxhai::Runner::Default
      end

      result = @system.data.dup.delete_if { |k, v| !whitelist_attributes.include?(k) }.merge(
        "languages" => languages,
        "counters" => counters,
        "current_user" => current_user,
        "domain" => domain,
        "hostname" => hostname,
        "machinename" => hostname,
        "fqdn" => fqdn,
        "ipaddress" => ipaddress,
        "keys" => keys,
        "macaddress" => macaddress,
        "network" => network,
        "uptime" => uptime,
        "uptime_seconds" => uptime_seconds,
        "idle" => uptime,
        "idletime_seconds" => uptime_seconds,
        "cpu" => cpu,
        "memory" => memory,
        "virtualization" => virtualization,
        "time" => time
      )

      puts JSON.pretty_generate(result.sort.to_h)
    end
  end
end
