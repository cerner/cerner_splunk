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

class Chef
  module Sugar
    module PlatformFamily
      extend self

      # these helpers have been moved to core chef
      if !defined?(Chef::VERSION) || Gem::Requirement.new("< 15.4.70").satisfied_by?(Gem::Version.new(Chef::VERSION))

        #
        # Determine if the current node is a member of the arch family.
        #
        # @param [Chef::Node] node
        #
        # @return [Boolean]
        #
        def arch_linux?(node)
          node['platform_family'] == 'arch'
        end
        alias_method :arch?, :arch_linux?

        #
        # Determine if the current node is a member of the debian family.
        #
        # @param [Chef::Node] node
        #
        # @return [Boolean]
        #
        def debian?(node)
          node['platform_family'] == 'debian'
        end

        #
        # Determine if the current node is a member of the fedora family.
        #
        # @param [Chef::Node] node
        #
        # @return [Boolean]
        #
        def fedora?(node)
          node['platform_family'] == 'fedora'
        end

        #
        # Determine if the current node is a member of the freebsd family.
        #
        # @param [Chef::Node] node
        #
        # @return [Boolean]
        #
        def freebsd?(node)
          node['platform_family'] == 'freebsd'
        end

        #
        # Determine if the current node is a member of the arch family.
        #
        # @param [Chef::Node] node
        #
        # @return [Boolean]
        #
        def gentoo?(node)
          node['platform_family'] == 'gentoo'
        end

        #
        # Determine if the current node is a member of the OSX family.
        #
        # @param [Chef::Node] node
        #
        # @return [Boolean]
        #
        def mac_os_x?(node)
          node['platform_family'] == 'mac_os_x'
        end
        alias_method :osx?, :mac_os_x?
        alias_method :mac?, :mac_os_x?

        #
        # Determine if the current node is a member of the openbsd family.
        #
        # @param [Chef::Node] node
        #
        # @return [Boolean]
        #
        def openbsd?(node)
          node['platform_family'] == 'openbsd'
        end

        #
        # Determine if the current node is a member of the redhat family.
        #
        # @param [Chef::Node] node
        #
        # @return [Boolean]
        #
        def rhel?(node)
          node['platform_family'] == 'rhel'
        end
        alias_method :redhat?, :rhel?
        alias_method :el?,     :rhel?

        #
        # Determine if the current node is a member of the slackware family.
        #
        # @param [Chef::Node] node
        #
        # @return [Boolean]
        #
        def slackware?(node)
          node['platform_family'] == 'slackware'
        end

        #
        # Determine if the current node is a member of the suse family.
        #
        # @param [Chef::Node] node
        #
        # @return [Boolean]
        #
        def suse?(node)
          node['platform_family'] == 'suse'
        end

        #
        # Determine if the current node is a member of the windows family.
        #
        # @param [Chef::Node] node
        #
        # @return [Boolean]
        #
        def windows?(node)
          node['platform_family'] == 'windows'
        end

        #
        # Determine if the current node is a member of the wrlinux family.
        #
        # @param [Chef::Node] node
        #
        # @return [Boolean]
        #
        def wrlinux?(node)
          node['platform_family'] == 'wrlinux'
        end

        #
        # Determine if the current system is a linux derivative
        #
        # @param [Chef::Node] node
        #
        # @return [Boolean]
        #
        def linux?(node)
          node['os'] == 'linux'
        end

      end
    end

    module DSL
      Chef::Sugar::PlatformFamily.instance_methods.each do |name|
        define_method(name) do
          Chef::Sugar::PlatformFamily.send(name, node)
        end
      end
    end
  end
end
