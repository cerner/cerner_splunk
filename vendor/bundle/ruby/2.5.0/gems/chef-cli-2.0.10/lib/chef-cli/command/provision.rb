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

require "ostruct"

require_relative "base"
require_relative "../chef_runner"
require_relative "../dist"

module ChefCLI

  module Command

    class Provision < Base

      banner("DEPRECATED: Chef provisioning has been removed from #{ChefCLI::Dist::PRODUCT}. If you require Chef Provisioning you will need to install an earlier version of these products!")

      def run(params = [])
        raise "Chef provisioning has been removed from #{ChefCLI::Dist::PRODUCT}. If you require Chef Provisioning you will need to install an earlier version of these products!"
      end

    end
  end
end
