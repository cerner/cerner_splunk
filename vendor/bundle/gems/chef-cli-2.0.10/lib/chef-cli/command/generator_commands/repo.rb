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
require_relative "../../dist"

module ChefCLI
  module Command
    module GeneratorCommands

      # ## Repo
      # chef generate repo path/to/basename --generator-cookbook=path/to/generator --policy-only
      #
      # Generates a full "chef-repo" directory structure.
      class Repo < Base

        banner "Usage: #{ChefCLI::Dist::EXEC} generate repo NAME [options]"

        attr_reader :errors
        attr_reader :repo_name_or_path

        option :policy_only,
          short:        "-p",
          long:         "--policy-only",
          description:  "Create a repository to store Policyfiles only, not cookbooks.",
          default:      false

        option :roles,
          short:        "-r",
          long:         "--roles",
          description:  "Create roles and environments directories instead of using Policyfiles.",
          default:      nil

        option :policy,
          short:        "-P",
          long:         "--policy",
          description:  "Use Policyfiles instead of roles and environments.",
          boolean:      true,
          default:      nil

        option :verbose,
          short:        "-V",
          long:         "--verbose",
          description:  "Show detailed output from the generator",
          boolean:      true,
          default:      false

        options.merge!(SharedGeneratorOptions.options)

        def initialize(params)
          @params_valid = true
          @repo_name = nil
          @use_policy = true
          @verbose = false
          super
        end

        def run
          read_and_validate_params
          if params_valid?
            setup_context
            msg("Generating Chef Infra repo #{repo_name}")
            chef_runner.converge
            msg("")
            msg("Your new Chef Infra repo is ready! Type `cd #{repo_name}` to enter it.")
            0
          else
            err(opt_parser)
            1
          end
        end

        def setup_context
          super
          Generator.add_attr_to_context(:verbose, verbose?)
          Generator.add_attr_to_context(:repo_root, repo_root)
          Generator.add_attr_to_context(:repo_name, repo_name)
          Generator.add_attr_to_context(:use_policy, use_policy?)
        end

        def recipe
          "repo"
        end

        def repo_name
          File.basename(repo_full_path)
        end

        def repo_root
          File.dirname(repo_full_path)
        end

        def repo_full_path
          File.expand_path(repo_name_or_path, Dir.pwd)
        end

        def use_policy?
          @use_policy
        end

        def verbose?
          @verbose
        end

        def read_and_validate_params
          arguments = parse_options(params)
          @repo_name_or_path = arguments[0]
          unless @repo_name_or_path
            @params_valid = false
          end
          if !config[:roles].nil? && !config[:policy].nil?
            err("Roles and Policyfiles are exclusive. Please only select one.")
            @params_valid = false
          end
          if config[:roles]
            @use_policy = false
          end
        end

        def params_valid?
          @params_valid
        end
      end
    end
  end
end
