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
    module Architecture
      extend self

      # these helpers have been moved to core-chef
      if !defined?(Chef::VERSION) || Gem::Requirement.new("< 15.4.70").satisfied_by?(Gem::Version.new(Chef::VERSION))
        #
        # Determine if the current architecture is 64-bit
        #
        # @return [Boolean]
        #
        def _64_bit?(node)
          %w(amd64 x86_64 ppc64 ppc64le s390x ia64 sparc64 aarch64 arch64 arm64 sun4v sun4u s390x)
            .include?(node['kernel']['machine']) || ( node['kernel']['bits'] == '64' )
        end

        #
        # Determine if the current architecture is 32-bit
        #
        # @todo Make this more than "not 64-bit"
        #
        # @return [Boolean]
        #
        def _32_bit?(node)
          !_64_bit?(node)
        end

        #
        # Determine if the current architecture is i386
        #
        # @return [Boolean]
        #
        def i386?(node)
          _32_bit?(node) && intel?(node)
        end

        #
        # Determine if the current architecture is Intel.
        #
        # @return [Boolean]
        #
        def intel?(node)
          %w(i86pc i386 x86_64 amd64 i686)
            .include?(node['kernel']['machine'])
        end

        #
        # Determine if the current architecture is SPARC.
        #
        # @return [Boolean]
        #
        def sparc?(node)
          %w(sun4u sun4v)
            .include?(node['kernel']['machine'])
        end

        #
        # Determine if the current architecture is Powerpc64 Big Endian
        #
        # @return [Boolean]
        #
        def ppc64?(node)
          %w(ppc64)
            .include?(node['kernel']['machine'])
        end

        #
        # Determine if the current architecture is Powerpc64 Little Endian
        #
        # @return [Boolean]
        #
        def ppc64le?(node)
          %w(ppc64le)
            .include?(node['kernel']['machine'])
        end

        #
        # Determine if the current architecture is PowerPC
        #
        # @return [Boolean]
        #
        def powerpc?(node)
          %w(powerpc)
            .include?(node['kernel']['machine'])
        end

        #
        # Determine if the current architecture is ARM with Hard Float
        #
        # @return [Boolean]
        #
        def armhf?(node)
          # Add more arm variants as needed here
          %w(armv6l armv7l)
            .include?(node['kernel']['machine'])
        end

        #
        # Determine if the current architecture is AArch64
        #
        # @return [Boolean]
        #
        def aarch64?(node)
          # Add more arm variants as needed here
          %w(aarch64)
            .include?(node['kernel']['machine'])
        end

        #
        # Determine if the current architecture is s390x
        #
        # @return [Boolean]
        #
        def s390x?(node)
          %w(s390x)
            .include?(node['kernel']['machine'])
        end
      end
    end

    module DSL
      if !defined?(Chef::VERSION) || Gem::Requirement.new("< 15.4.70").satisfied_by?(Gem::Version.new(Chef::VERSION))
        # @see Chef::Sugar::Architecture#_64_bit?
        def _64_bit?; Chef::Sugar::Architecture._64_bit?(node); end

        # @see Chef::Sugar::Architecture#_32_bit?
        def _32_bit?; Chef::Sugar::Architecture._32_bit?(node); end

        # @see Chef::Sugar::Architecture#intel?
        def i386?; Chef::Sugar::Architecture.i386?(node); end

        # @see Chef::Sugar::Architecture#intel?
        def intel?; Chef::Sugar::Architecture.intel?(node); end

        # @see Chef::Sugar::Architecture#sparc?
        def sparc?; Chef::Sugar::Architecture.sparc?(node); end

        # @see Chef::Sugar::Architecture#ppc64?
        def ppc64?; Chef::Sugar::Architecture.ppc64?(node); end

        # @see Chef::Sugar::Architecture#ppc64le?
        def ppc64le?; Chef::Sugar::Architecture.ppc64le?(node); end

        # @see Chef::Sugar::Architecture#powerpc?
        def powerpc?; Chef::Sugar::Architecture.powerpc?(node); end

        # @see Chef::Sugar::Architecture#arm?
        def armhf?; Chef::Sugar::Architecture.armhf?(node); end

        # @see Chef::Sugar::Architecture#aarch64?
        def aarch64?; Chef::Sugar::Architecture.aarch64?(node); end

        # @see Chef::Sugar::Architecture#s390x?
        def s390x?; Chef::Sugar::Architecture.s390x?(node); end

      end
    end
  end
end
