#
# Copyright 2015, Nathan Williams <nath.e.will@gmail.com>
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
    module Init
      extend self

      #
      # Determine if the current init system is systemd.
      #
      # @return [Boolean]
      #
      def systemd?(node)
        File.exist?('/bin/systemctl')
      end

      #
      # Determine if the current init system is upstart.
      #
      # @return [Boolean]
      #
      def upstart?(node)
        File.executable?('/sbin/initctl')
      end

      #
      # Determine if the current init system is runit.
      #
      # @return [Boolean]
      #
      def runit?(node)
        File.executable?('/sbin/runit-init')
      end
    end

    module DSL
      # @see Chef::Sugar::Init#systemd?
      def systemd?; Chef::Sugar::Init.systemd?(node); end

      # @see Chef::Sugar::Init#upstart?
      def upstart?; Chef::Sugar::Init.upstart?(node); end

      # @see Chef::Sugar::Init#runit?
      def runit?; Chef::Sugar::Init.runit?(node); end
    end
  end
end
