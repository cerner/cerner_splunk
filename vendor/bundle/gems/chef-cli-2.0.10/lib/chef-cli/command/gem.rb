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

require_relative "base"
require_relative "../dist"
require "rubygems" unless defined?(Gem)
require "rubygems/gem_runner"
require "rubygems/exceptions"
require "pp" unless defined?(PP)

module ChefCLI
  module Command

    # Forwards all commands to rubygems.
    class GemForwarder < ChefCLI::Command::Base
      banner "Usage: #{ChefCLI::Dist::EXEC} gem GEM_COMMANDS_AND_OPTIONS"

      def run(params)
        retval = Gem::GemRunner.new.run( params.clone )
        retval.nil? ? true : retval
      rescue Gem::SystemExitException => e
        exit( e.exit_code )
      end

      # Lazy solution: By automatically returning false, we force ChefCLI::Base to
      # call this class' run method, so that Gem::GemRunner can handle the -v flag
      # appropriately (showing the gem version, or installing a specific version
      # of a gem).
      def needs_version?(params)
        false
      end
    end
  end
end
