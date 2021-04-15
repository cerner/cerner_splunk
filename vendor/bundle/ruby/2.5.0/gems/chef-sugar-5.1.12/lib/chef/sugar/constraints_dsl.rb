#
# Copyright 2013-2015, Seth Vargo <sethvargo@gmail.com>
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

require_relative 'constraints'

class Chef
  module Sugar
    #
    # The Constraints DSL methods were broken out into this separate
    # file to allow projects (such as Omnibus) to consume the
    # Chef::Sugar::Constraints classes without the DSL methods
    # stepping on existing methods of the same name.
    #
    module Constraints
      extend self

      #
      # Shortcut method for creating a new {Version} object.
      #
      # @param [String] version
      #   the version (as a string) to create
      #
      # @return [Chef::Sugar::Constraints::Version]
      #   the new version object
      #
      def version(version)
        Chef::Sugar::Constraints::Version.new(version)
      end

      #
      # Shortcut method for creating a new {Constraint} object.
      #
      # @param [String, Array<String>] constraints
      #   the list of constraints to use
      #
      # @return [Chef::Sugar::Constraints::Constraint]
      #   the new constraint object
      #
      def constraint(*constraints)
        Chef::Sugar::Constraints::Constraint.new(*constraints)
      end
    end

    module DSL
      # @see Chef::Sugar::Constraints#version
      def version(version)
        Chef::Sugar::Constraints::Version.new(version)
      end

      # @see Chef::Sugar::Constraints#constraint
      def constraint(*constraints)
        Chef::Sugar::Constraints.constraint(*constraints)
      end

      #
      # This wrapper/convenience method is only available in the recipe DSL. It
      # creates a new version object from the {Chef::VERSION}.
      #
      # @example Check if Chef 11+
      #   chef_version.satisfies?('>= 11.0.0')
      #
      # @return [Chef::Sugar::Constraints::Version]
      #   a version object, wrapping the current {Chef::VERSION}
      #
      def chef_version
        version(Chef::VERSION)
      end
    end
  end
end
