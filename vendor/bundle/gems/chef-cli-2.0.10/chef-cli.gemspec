#
# Copyright:: Copyright (c) 2014-2019, Chef Software Inc.
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

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "chef-cli/version"

Gem::Specification.new do |gem|
  gem.name          = "chef-cli"
  gem.version       = ChefCLI::VERSION
  gem.authors       = ["Chef Software, Inc."]
  gem.email         = ["info@chef.io"]
  gem.description   = "A streamlined development and deployment workflow for Chef platform."
  gem.summary       = gem.description
  gem.license       = "Apache-2.0"
  gem.homepage      = "https://www.chef.io/"

  gem.required_ruby_version = ">= 2.4"

  gem.files = %w{Rakefile LICENSE} +
    Dir.glob("Gemfile*") + # Includes Gemfile and locks
    Dir.glob("*.gemspec") +
    Dir.glob("{lib,spec}/**/*", File::FNM_DOTMATCH).reject { |f| File.directory?(f) }
  gem.executables   = %w{ chef-cli }
  gem.test_files    = gem.files.grep(%r{^spec/})
  gem.require_paths = ["lib"]

  gem.add_dependency "mixlib-cli", ">= 1.7", "< 3.0"
  gem.add_dependency "mixlib-shellout", ">= 2.0", "< 4.0"
  gem.add_dependency "ffi-yajl", ">= 1.0", "< 3.0"
  gem.add_dependency "minitar", "~> 0.6"
  gem.add_dependency "chef", ">= 14.0"
  gem.add_dependency "solve", "< 5.0", "> 2.0"
  gem.add_dependency "addressable", ">= 2.3.5", "< 2.8"
  gem.add_dependency "cookbook-omnifetch", "~> 0.5"
  gem.add_dependency "diff-lcs", "~> 1.0"
  gem.add_dependency "paint", ">= 1", "< 3"
  gem.add_dependency "license-acceptance", "~> 1.0", ">= 1.0.11"
end
