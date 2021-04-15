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
    module Kitchen
      extend self

      # these helpers have been moved to core-chef
      if !defined?(Chef::VERSION) || Gem::Requirement.new("< 15.4.70").satisfied_by?(Gem::Version.new(Chef::VERSION))
        #
        # Returns true if the current node is provisioned by Test Kitchen.
        #
        # @param [Chef::Node] node
        #   the node to check
        #
        # @return [Boolean]
        #
        def kitchen?(node)
          !ENV['TEST_KITCHEN'].nil?
        end
      end
    end

    module DSL
      if !defined?(Chef::VERSION) || Gem::Requirement.new("< 15.4.70").satisfied_by?(Gem::Version.new(Chef::VERSION))
        # @see Chef::Sugar::Kitchen#kitchen?
        def kitchen?; Chef::Sugar::Kitchen.kitchen?(node); end
      end
    end
  end
end
