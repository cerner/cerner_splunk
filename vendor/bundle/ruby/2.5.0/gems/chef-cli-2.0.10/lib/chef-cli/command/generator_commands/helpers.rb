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

require_relative "cookbook_code_file"
require_relative "../../dist"

module ChefCLI
  module Command
    module GeneratorCommands
      # chef generate helpers [path/to/cookbook_root] NAME
      class Helpers < CookbookCodeFile

        banner "Usage: #{ChefCLI::Dist::EXEC} generate helpers [path/to/cookbook] NAME [options]"

        options.merge!(SharedGeneratorOptions.options)

        def recipe
          "helpers"
        end
      end
    end
  end
end
