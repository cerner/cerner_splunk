name             'cerner_splunk'
maintainer       'Healthe Intent Infrastructure - Cerner Innovation, Inc.'
maintainer_email 'splunk@cerner.com'
license          'Apache-2.0'
description      'Installs/Configures Splunk Servers and Forwarders'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '2.21.1'

source_url       'https://github.com/cerner/cerner_splunk'
issues_url       'https://github.com/cerner/cerner_splunk/issues'

chef_version     '~> 12.4' if respond_to?(:chef_version)

depends          'chef-vault', '~> 3.0'
depends          'ulimit', '~> 0.3'
depends          'xml', '~> 1.2'

supports         'redhat', '>= 5.5'
supports         'ubuntu', '>= 12.04'
supports         'windows', '>= 6.1'
