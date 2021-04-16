#
# Copyright:: Copyright (c) 2014-2018 Chef Software Inc.
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

require "cookbook-omnifetch"
require_relative "shell_out"
require_relative "cookbook_metadata"
require_relative "helpers"

require "chef/http/simple"

# Configure CookbookOmnifetch's dependency injection settings to use our classes and config.
CookbookOmnifetch.configure do |c|
  c.cache_path = File.expand_path(File.join(ChefCLI::Helpers.package_home, "cache"))
  c.storage_path = Pathname.new(File.expand_path(File.join(ChefCLI::Helpers.package_home, "cache", "cookbooks")))
  c.shell_out_class = ChefCLI::ShellOut
  c.cached_cookbook_class = ChefCLI::CookbookMetadata
  c.chef_server_download_concurrency = 10
end
