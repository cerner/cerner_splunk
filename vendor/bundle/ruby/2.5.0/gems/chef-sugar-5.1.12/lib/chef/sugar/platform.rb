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
    module Platform
      extend self

      PLATFORM_VERSIONS = {
        'debian' => {
          'squeeze' => '6',
          'wheezy'  => '7',
          'jessie'  => '8',
          'stretch' => '9',
          'buster'  => '10',
        },
        'linuxmint' => {
          'tara'   => '19',
          'sarah'  => '18',
          'qiana'  => '17',
          'petra'  => '16',
          'olivia' => '15',
          'nadia'  => '14',
          'maya'   => '13',
          'lisa'   => '12',
        },
        'mac_os_x' => {
          'lion'          => '10.7',
          'mountain_lion' => '10.8',
          'mavericks'     => '10.9',
          'yosemite'      => '10.10',
          'el_capitan'    => '10.11',
          'sierra'        => '10.12',
          'high_sierra'   => '10.13',
          'mojave'        => '10.14',
        },
        'redhat' => {
          'santiago' => '6',
          '6'        => '6',
          'maipo'    => '7',
          '7'        => '7',
          'oompa'    => '8',
          '8'        => '8'
        },
        'centos' => {
          'final' => '6',
          '6'     => '6',
          'core'  => '7',
          '7'     => '7'
        },
        'solaris' => {
          '7'  => '5.7',
          '8'  => '5.8',
          '9'  => '5.9',
          '10' => '5.10',
          '11' => '5.11',
        },
        'ubuntu' => {
          'lucid'    => '10.04',
          'maverick' => '10.10',
          'natty'    => '11.04',
          'oneiric'  => '11.10',
          'precise'  => '12.04',
          'quantal'  => '12.10',
          'raring'   => '13.04',
          'saucy'    => '13.10',
          'trusty'   => '14.04',
          'utopic'   => '14.10',
          'vivid'    => '15.04',
          'wily'     => '15.10',
          'xenial'   => '16.04',
          'zesty'    => '17.04',
          'artful'   => '17.10',
          'bionic'   => '18.04',
          'cosmic'   => '18.10',
        },
      }

      COMPARISON_OPERATORS = {
        'after'        => ->(a, b) { a > b },
        'after_or_at'  => ->(a, b) { a >= b },
        ''             => ->(a, b) { a == b },
        'before'       => ->(a, b) { a < b },
        'before_or_at' => ->(a, b) { a <= b },
      }

      # Dynamically define custom matchers at runtime in a matrix. For each
      # Platform, we create a map of named versions to their numerical
      # equivalents (e.g. debian_before_squeeze?).
      PLATFORM_VERSIONS.each do |platform, versions|
        versions.each do |name, version|
          COMPARISON_OPERATORS.each do |operator, block|
            method_name = "#{platform}_#{operator}_#{name}?".squeeze('_').to_sym
            define_method(method_name) do |node|
              # Find the highest precedence that we actually care about based
              # off of what was given to us in the list.
              length = version.split('.').size
              check  = node['platform_version'].split('.')[0...length].join('.')

              # Calling #to_f will ensure we only check major versions since
              # '10.04.4'.to_f #=> 10.04. We also use a regex to match on
              # platform so things like `solaris2` match on `solaris`.
              node['platform'] =~ %r(^#{platform}) && block.call(check.to_f, version.to_f)
            end
          end
        end
      end

      # these helpers have been moved to core chef
      if !defined?(Chef::VERSION) || Gem::Requirement.new("< 15.4.70").satisfied_by?(Gem::Version.new(Chef::VERSION))
        #
        # Determine if the current node is linux mint.
        #
        # @param [Chef::Node] node
        #
        # @return [Boolean]
        #
        def linux_mint?(node)
          node['platform'] == 'linuxmint'
        end
        alias_method :mint?, :linux_mint?

        #
        # Determine if the current node is ubuntu.
        #
        # @param [Chef::Node] node
        #
        # @return [Boolean]
        #
        def ubuntu?(node)
          node['platform'] == 'ubuntu'
        end

        #
        # Determine if the current node is debian (platform, not platform_family).
        #
        # @param [Chef::Node] node
        #
        # @return [Boolean]
        #
        def debian_platform?(node)
          node['platform'] == 'debian'
        end

        #
        # Determine if the current node is amazon linux.
        #
        # @param [Chef::Node] node
        #
        # @return [Boolean]
        #
        def amazon_linux?(node)
          node['platform'] == 'amazon'
        end
        alias_method :amazon?, :amazon_linux?

        #
        # Determine if the current node is centos.
        #
        # @param [Chef::Node] node
        #
        # @return [Boolean]
        #
        def centos?(node)
          node['platform'] == 'centos'
        end

        #
        # Determine if the current node is oracle linux.
        #
        # @param [Chef::Node] node
        #
        # @return [Boolean]
        #
        def oracle_linux?(node)
          node['platform'] == 'oracle'
        end
        alias_method :oracle?, :oracle_linux?

        #
        # Determine if the current node is scientific linux.
        #
        # @param [Chef::Node] node
        #
        # @return [Boolean]
        #
        def scientific_linux?(node)
          node['platform'] == 'scientific'
        end
        alias_method :scientific?, :scientific_linux?

        #
        # Determine if the current node is redhat enterprise.
        #
        # @param [Chef::Node] node
        #
        # @return [Boolean]
        #
        def redhat_enterprise_linux?(node)
          node['platform'] == 'redhat'
        end
        alias_method :redhat_enterprise?, :redhat_enterprise_linux?

        #
        # Determine if the current node is fedora (platform, not platform_family).
        #
        # @param [Chef::Node] node
        #
        # @return [Boolean]
        #
        def fedora_platform?(node)
          node['platform'] == 'fedora'
        end

        #
        # Determine if the current node is solaris2
        #
        # @param [Chef::Node] node
        #
        # @return [Boolean]
        #
        def solaris2?(node)
          node['platform'] == 'solaris2'
        end
        alias_method :solaris?, :solaris2?

        #
        # Determine if the current node is aix
        #
        # @param [Chef::Node] node
        #
        # @return [Boolean]
        #
        def aix?(node)
          node['platform'] == 'aix'
        end

        #
        # Determine if the current node is smartos
        #
        # @param [Chef::Node] node
        #
        # @return [Boolean]
        #
        def smartos?(node)
          node['platform'] == 'smartos'
        end

        #
        # Determine if the current node is omnios
        #
        # @param [Chef::Node] node
        #
        # @return [Boolean]
        #
        def omnios?(node)
          node['platform'] == 'omnios'
        end

        #
        # Determine if the current node is raspbian
        #
        # @param [Chef::Node] node
        #
        # @return [Boolean]
        #
        def raspbian?(node)
          node['platform'] == 'raspbian'
        end

        #
        # Determine if the current node is a Cisco nexus device
        #
        # @param [Chef::Node] node
        #
        # @return [Boolean]
        #
        def nexus?(node)
          node['platform'] == 'nexus'
        end

        #
        # Determine if the current node is a Cisco IOS-XR device
        #
        # @param [Chef::Node] node
        #
        # @return [Boolean]
        #
        def ios_xr?(node)
          node['platform'] == 'ios_xr'
        end

      end

      #
      # Return the platform_version for the node. Acts like a String
      # but also provides a mechanism for checking version constraints.
      #
      # @param [Chef::Node] node
      #
      # @return [Chef::Sugar::Constraints::Version]
      #
      def platform_version(node)
        Chef::Sugar::Constraints::Version.new(node['platform_version'])
      end
    end

    module DSL
      Chef::Sugar::Platform.instance_methods.each do |name|
        define_method(name) do
          Chef::Sugar::Platform.send(name, node)
        end
      end
    end
  end
end
