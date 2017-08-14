# frozen_string_literal: true

name              'cerner_splunk'
maintainer        'Healthe Intent Infrastructure - Cerner Innovation, Inc.'
maintainer_email  'splunk@cerner.com'
license           'Apache-2.0'
description       'Installs/Configures Splunk Servers and Forwarders'
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           '3.0.0'

source_url        'https://github.com/cerner/cerner_splunk'
issues_url        'https://github.com/cerner/cerner_splunk/issues'

depends           'chef-vault', '~> 3.0'
depends           'cerner_splunk_ingredient'

gem               'unix-crypt'

chef_version      '~> 12.16'

supports          'redhat', '>= 6.8'
supports          'ubuntu', '>= 12.04'
supports          'windows', '>= 6.1'
