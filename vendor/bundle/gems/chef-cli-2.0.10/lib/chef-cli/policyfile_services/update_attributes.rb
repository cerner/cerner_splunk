#
# Copyright:: Copyright (c) 2015 Chef Software Inc.
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

require_relative "../helpers"
require_relative "../policyfile/storage_config"
require_relative "../policyfile/lock_applier"
require_relative "../service_exceptions"
require_relative "../policyfile_compiler"

module ChefCLI
  module PolicyfileServices

    class UpdateAttributes

      include Policyfile::StorageConfigDelegation
      include ChefCLI::Helpers

      attr_reader :ui
      attr_reader :storage_config
      attr_reader :chef_config

      def initialize(policyfile: nil, ui: nil, root_dir: nil, chef_config: nil)
        @ui = ui

        policyfile_rel_path = policyfile || "Policyfile.rb"
        policyfile_full_path = File.expand_path(policyfile_rel_path, root_dir)
        @storage_config = Policyfile::StorageConfig.new.use_policyfile(policyfile_full_path)
        @updated = false
        @chef_config = chef_config
      end

      def run
        assert_policy_and_lock_present!
        prepare_constraints

        if policyfile_compiler.default_attributes != policyfile_lock.default_attributes
          policyfile_lock.default_attributes = policyfile_compiler.default_attributes
          @updated = true
        end

        if policyfile_compiler.override_attributes != policyfile_lock.override_attributes
          policyfile_lock.override_attributes = policyfile_compiler.override_attributes
          @updated = true
        end

        if updated_lock?
          with_file(policyfile_lock_expanded_path) do |f|
            f.print(FFI_Yajl::Encoder.encode(policyfile_lock.to_lock, pretty: true ))
          end
          ui.msg("Updated attributes in #{policyfile_lock_expanded_path}")
        else
          ui.msg("Attributes already up to date")
        end
      rescue => error
        raise PolicyfileUpdateError.new("Failed to update Policyfile lock", error)
      end

      def updated_lock?
        @updated
      end

      def policyfile_content
        @policyfile_content ||= IO.read(policyfile_expanded_path)
      end

      def policyfile_compiler
        @policyfile_compiler ||= ChefCLI::PolicyfileCompiler.evaluate(policyfile_content, policyfile_expanded_path, ui: ui, chef_config: chef_config)
      end

      def policyfile_lock_content
        @policyfile_lock_content ||= IO.read(policyfile_lock_expanded_path)
      end

      def policyfile_lock
        @policyfile_lock ||= begin
          lock_data = FFI_Yajl::Parser.new.parse(policyfile_lock_content)
          PolicyfileLock.new(storage_config, ui: ui).build_from_lock_data(lock_data)
        end
      end

      def assert_policy_and_lock_present!
        unless File.exist?(policyfile_expanded_path)
          raise PolicyfileNotFound, "Policyfile not found at path #{policyfile_expanded_path}"
        end
        unless File.exist?(policyfile_lock_expanded_path)
          raise LockfileNotFound, "Policyfile lock not found at path #{policyfile_lock_expanded_path}"
        end
      end

      def prepare_constraints
        # Ensure we recompute policies from their (possibly updated) source
        Policyfile::LockApplier.new(policyfile_lock, policyfile_compiler)
          .with_unlocked_policies(:all)
          .apply!
      end
    end
  end
end
