# frozen_string_literal: true

name             'cerner_splunk'
maintainer       'Healthe Intent Infrastructure - Cerner Innovation, Inc.'
maintainer_email 'splunk@cerner.com'
license          'Apache-2.0'
description      'Installs/Configures Splunk Servers and Forwarders'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '2.56.1'

source_url       'https://github.com/cerner/cerner_splunk'
issues_url       'https://github.com/cerner/cerner_splunk/issues'

chef_version     '>= 15', '< 18'

depends          'chef-vault', '> 3.0'
depends          'ulimit', '~> 1.0'
depends          'line', '~> 2.1'

supports         'redhat', '>= 6.7'
supports         'ubuntu', '>= 12.04'
supports         'windows', '>= 6.1'
