#
# Copyright:: Copyright (c) 2015-2019 Chef Software Inc.
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

require_relative "base"
require_relative "../cookbook_omnifetch"
require_relative "../ui"
require_relative "../version"
require_relative "../dist"
require "mixlib/shellout" unless defined?(Mixlib::ShellOut)
require "yaml"

module ChefCLI
  module Command
    class Env < ChefCLI::Command::Base
      banner "Usage: #{ChefCLI::Dist::EXEC} env"

      attr_accessor :ui

      def initialize(*args)
        super
        @ui = UI.new
      end

      def run(params)
        info = {}
        info["#{ChefCLI::Dist::PRODUCT}"] = workstation_info
        info["Ruby"] = ruby_info
        info["Path"] = paths
        ui.msg info.to_yaml
      end

      def workstation_info
        info = {}
        if omnibus_install?
          info["Version"] = ChefCLI::VERSION
          info["Home"] = package_home
          info["Install Directory"] = omnibus_root
          info["Policyfile Config"] = policyfile_config
        else
          info["Version"] = "Not running from within Workstation"
        end
        info
      end

      def ruby_info
        {}.tap do |ruby|
          ruby["Executable"] = Gem.ruby
          ruby["Version"] = RUBY_VERSION
          ruby["RubyGems"] = {}.tap do |rubygems|
            rubygems["RubyGems Version"] = Gem::VERSION
            rubygems["RubyGems Platforms"] = Gem.platforms.map(&:to_s)
            rubygems["Gem Environment"] = gem_environment
          end
        end
      end

      def gem_environment
        h = {}
        h["GEM ROOT"] = omnibus_env["GEM_ROOT"]
        h["GEM HOME"] = omnibus_env["GEM_HOME"]
        h["GEM PATHS"] = omnibus_env["GEM_PATH"].split(File::PATH_SEPARATOR)
      rescue OmnibusInstallNotFound
        h["GEM_ROOT"] = ENV["GEM_ROOT"] if ENV.key?("GEM_ROOT")
        h["GEM_HOME"] = ENV["GEM_HOME"] if ENV.key?("GEM_HOME")
        h["GEM PATHS"] = ENV["GEM_PATH"].split(File::PATH_SEPARATOR) if ENV.key?("GEM_PATH") && !ENV.key?("GEM_PATH").nil?
      ensure
        h
      end

      def paths
        omnibus_env["PATH"].split(File::PATH_SEPARATOR)
      rescue OmnibusInstallNotFound
        ENV["PATH"].split(File::PATH_SEPARATOR)
      end

      def policyfile_config
        {}.tap do |h|
          h["Cache Path"] = CookbookOmnifetch.cache_path
          h["Storage Path"] = CookbookOmnifetch.storage_path.to_s
        end
      end

    end
  end
end
