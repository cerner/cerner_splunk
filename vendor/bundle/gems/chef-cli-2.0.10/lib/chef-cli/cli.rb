#
# Copyright:: Copyright (c) 2014-2019 Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "mixlib/cli" unless defined?(Mixlib::CLI)
require_relative "version"
require_relative "commands_map"
require_relative "builtin_commands"
require_relative "helpers"
require_relative "ui"
require_relative "dist"
require "chef/util/path_helper"
require "chef/mixin/shell_out"
require "bundler"

module ChefCLI
  class CLI
    include Mixlib::CLI
    include ChefCLI::Helpers
    include Chef::Mixin::ShellOut

    banner(<<~BANNER)
      Usage:
          #{ChefCLI::Dist::EXEC} -h/--help
          #{ChefCLI::Dist::EXEC} -v/--version
          #{ChefCLI::Dist::EXEC} command [arguments...] [options...]
    BANNER

    option :version,
      short: "-v",
      long: "--version",
      description: "Show #{ChefCLI::Dist::PRODUCT} version",
      boolean: true

    option :help,
      short: "-h",
      long: "--help",
      description: "Show this message",
      boolean: true

    attr_reader :argv

    def initialize(argv)
      @argv = argv
      super() # mixlib-cli #initialize doesn't allow arguments
    end

    def run(enforce_license: false)
      sanity_check!

      subcommand_name, *subcommand_params = argv

      #
      # Runs the appropriate subcommand if the given parameters contain any
      # subcommands.
      #
      if subcommand_name.nil? || option?(subcommand_name)
        handle_options
      elsif have_command?(subcommand_name)
        subcommand = instantiate_subcommand(subcommand_name)
        exit_code = subcommand.run_with_default_options(enforce_license, subcommand_params)
        exit normalized_exit_code(exit_code)
      else
        err "Unknown command `#{subcommand_name}'."
        show_help
        exit 1
      end
    rescue OptionParser::InvalidOption => e
      err(e.message)
      show_help
      exit 1
    end

    # If no subcommand is given, then this class is handling the CLI request.
    def handle_options
      parse_options(argv)
      if config[:version]
        show_version
      else
        show_help
      end
      exit 0
    end

    def show_version
      if omnibus_install?
        show_version_via_version_manifest
      else
        show_version_via_shell_out
      end
    end

    def show_version_via_version_manifest
      msg("#{ChefCLI::Dist::PRODUCT} version: #{manifest_field("build_version")}")
      { "#{ChefCLI::Dist::INFRA_CLIENT_PRODUCT}": "#{ChefCLI::Dist::INFRA_CLIENT_GEM}",
        "#{ChefCLI::Dist::INSPEC_PRODUCT}": "#{ChefCLI::Dist::INSPEC_CLI}",
        "#{ChefCLI::Dist::CLI_PRODUCT}": "#{ChefCLI::Dist::CLI_GEM}",
        "Test Kitchen": "test-kitchen",
        "Cookstyle": "cookstyle",
      }.each do |name, gem|
        msg("#{name} version: #{gem_version(gem)}")
      end
    end

    def show_version_via_shell_out
      msg("#{ChefCLI::Dist::PRODUCT} version: #{ChefCLI::VERSION}")
      { "#{ChefCLI::Dist::INFRA_CLIENT_PRODUCT}": "#{ChefCLI::Dist::INFRA_CLIENT_CLI}",
        "#{ChefCLI::Dist::INSPEC_PRODUCT}": "#{ChefCLI::Dist::INSPEC_CLI}",
        "Test Kitchen": "kitchen",
        "Cookstyle": "cookstyle",
      }.each do |name, cli|
        result = Bundler.with_clean_env { shell_out("#{cli} --version") }
        if result.exitstatus != 0
          msg("#{name} version: ERROR")
        else
          version = result.stdout.lines.first.scan(/(?:master\s)?[\d+\.\(\)]+\S+/).join("\s")
          msg("#{name} version: #{version}")
        end
      end
    end

    def show_help
      msg(banner)
      msg("\nAvailable Commands:")

      justify_length = subcommands.map(&:length).max + 2
      subcommand_specs.each do |name, spec|
        next if spec.hidden

        msg("    #{"#{name}".ljust(justify_length)}#{spec.description}")
      end
    end

    def exit(n)
      Kernel.exit(n)
    end

    def commands_map
      ChefCLI.commands_map
    end

    def have_command?(name)
      commands_map.have_command?(name)
    end

    def subcommands
      commands_map.command_names
    end

    def subcommand_specs
      commands_map.command_specs
    end

    def option?(param)
      param =~ /^-/
    end

    def instantiate_subcommand(name)
      commands_map.instantiate(name)
    end

    private

    def manifest_field(field)
      if manifest_hash[field]
        manifest_hash[field]
      else
        "unknown"
      end
    end

    def gem_version(name)
      if gem_manifest_hash[name].is_a?(Array)
        gem_manifest_hash[name].first
      else
        "unknown"
      end
    end

    def manifest_hash
      require "json"
      @manifest_hash ||= JSON.parse(read_version_manifest_json)
    end

    def gem_manifest_hash
      require "json"
      @gem_manifest_hash ||= JSON.parse(read_gem_version_manifest_json)
    end

    def read_version_manifest_json
      File.read(File.join(omnibus_root, "version-manifest.json"))
    end

    def read_gem_version_manifest_json
      File.read(File.join(omnibus_root, "gem-version-manifest.json"))
    end

    def normalized_exit_code(maybe_integer)
      if maybe_integer.is_a?(Integer) && (0..255).cover?(maybe_integer)
        maybe_integer
      else
        0
      end
    end

    # Find PATH or Path correctly if we are on Windows
    def path_key
      env.keys.grep(/\Apath\Z/i).first
    end

    # upcase drive letters for comparison since ruby has a String#capitalize function
    def drive_upcase(path)
      if Chef::Platform.windows? && path[0] =~ /^[A-Za-z]$/ && path[1, 2] == ":\\"
        path.capitalize
      else
        path
      end
    end

    def env
      ENV
    end

    # catch the cases where users setup only the embedded_bin_dir in their path, or
    # when they have the embedded_bin_dir before the omnibus_bin_dir -- both of which will
    # defeat appbundler and interact very badly with our intent.
    def sanity_check!
      # When installed outside of omnibus, trust the user to configure their PATH
      return true unless omnibus_install?

      paths = env[path_key].split(File::PATH_SEPARATOR)
      paths.map! { |p| drive_upcase(Chef::Util::PathHelper.cleanpath(p)) }
      embed_index = paths.index(drive_upcase(Chef::Util::PathHelper.cleanpath(omnibus_embedded_bin_dir)))
      bin_index = paths.index(drive_upcase(Chef::Util::PathHelper.cleanpath(omnibus_bin_dir)))
      if embed_index
        if bin_index
          if embed_index < bin_index
            err("WARN: #{omnibus_embedded_bin_dir} is before #{omnibus_bin_dir} in your #{path_key}, please reverse that order.")
            err("WARN: consider using `#{ChefCLI::Dist::EXEC} shell-init <shell>` command to setup your environment correctly.")
          end
        else
          err("WARN: only #{omnibus_embedded_bin_dir} is present in your path, you must add #{omnibus_bin_dir} before that directory.")
          err("WARN: consider using `#{ChefCLI::Dist::EXEC} shell-init <shell>` command to setup your environment correctly.")
        end
      end
    end
  end
end
