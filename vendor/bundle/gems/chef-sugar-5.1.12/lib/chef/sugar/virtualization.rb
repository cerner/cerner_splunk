#
# Copyright 2014, Joseph J. Nuspl Jr. <nuspl@nvwls.com>
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
    module Virtualization
      extend self

      #
      # Determine if the current node is running under KVM.
      #
      # @param [Chef::Node] node
      #
      # @return [Boolean]
      #   true if the machine is currently running under KVM, false
      #   otherwise
      #
      def kvm?(node)
        node.key?('virtualization') && node['virtualization']['system'] == 'kvm'
      end

      #
      # Determine if the current node is running in a linux container.
      #
      # @param [Chef::Node] node
      #
      # @return [Boolean]
      #   true if the machine is currently running in a container, false
      #   otherwise
      #
      def lxc?(node)
        node.key?('virtualization') && node['virtualization']['system'] == 'lxc'
      end

      #
      # Determine if the current node is running under Parallels Desktop.
      #
      # @param [Chef::Node] node
      #
      # @return [Boolean]
      #   true if the machine is currently running under Parallels Desktop, false
      #   otherwise
      #
      def parallels?(node)
        node.key?('virtualization') && node['virtualization']['system'] == 'parallels'
      end

      #
      # Determine if the current node is running under VirtualBox.
      #
      # @param [Chef::Node] node
      #
      # @return [Boolean]
      #   true if the machine is currently running under VirtualBox, false
      #   otherwise
      #
      def virtualbox?(node)
        node.key?('virtualization') && node['virtualization']['system'] == 'vbox'
      end

      #
      # Determine if the current node is running under VMware.
      #
      # @param [Chef::Node] node
      #
      # @return [Boolean]
      #   true if the machine is currently running under VMware, false
      #   otherwise
      #
      def vmware?(node)
        node.key?('virtualization') && node['virtualization']['system'] == 'vmware'
      end

      #
      # Determine if the current node is running under openvz.
      #
      # @param [Chef::Node] node
      #
      # @return [Boolean]
      #   true if the machine is currently running under openvz, false
      #   otherwise
      #
      def openvz?(node)
        node.key?('virtualization') && node['virtualization']['system'] == 'openvz'
      end

      def virtual?(node)
        openvz?(node) || vmware?(node) || virtualbox?(node) || parallels?(node) || lxc?(node) || kvm?(node)
      end

      def physical?(node)
        !virtual?(node)
      end
    end

    module DSL
      # @see Chef::Sugar::Virtualization#kvm?
      def kvm?
        Chef::Sugar::Virtualization.kvm?(node)
      end

      # @see Chef::Sugar::Virtualization#lxc?
      def lxc?
        Chef::Sugar::Virtualization.lxc?(node)
      end

      # @see Chef::Sugar::Virtualization#parallels?
      def parallels?
        Chef::Sugar::Virtualization.parallels?(node)
      end

      # @see Chef::Sugar::Virtualization#virtualbox?
      def virtualbox?
        Chef::Sugar::Virtualization.virtualbox?(node)
      end

      # @see Chef::Sugar::Virtualization#vmware?
      def vmware?
        Chef::Sugar::Virtualization.vmware?(node)
      end

      # @see Chef::Sugar::Virtualization#openvz?
      def openvz?
        Chef::Sugar::Virtualization.openvz?(node)
      end

      # @see Chef::Sugar::Virtualization#virtual?
      def virtual?
        Chef::Sugar::Virtualization.virtual?(node)
      end

      # @see Chef::Sugar::Virtualization#physical?
      def physical?
        Chef::Sugar::Virtualization.physical?(node)
      end
    end
  end
end
