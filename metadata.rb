name             'cerner_splunk'
maintainer       'Healthe Intent Infrastructure - Cerner Innovation, Inc.'
maintainer_email 'splunk@cerner.com'
license          'Apache 2.0'
description      'Installs/Configures Splunk Servers and Forwarders'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '1.16.0'

source_url       'https://github.com/cerner/cerner_splunk' if defined?(:source_url)
issues_url       'https://github.com/cerner/cerner_splunk/issues' if defined?(:issues_url)

# Locking chef-vault to 1.3.0 due to the introduction of Ruby 2.x specific syntax in newer version. As long as Support
# for Chef 11 is needed. See https://github.com/chef-cookbooks/chef-vault/issues/41
depends          'chef-vault', '= 1.3.0'
depends          'ulimit', '~> 0.3.2'
depends          'xml', '~> 1.2'

supports         'redhat', '>= 5.5'
supports         'ubuntu', '>= 12.04'
supports         'windows', '>= 6.1'

# Chef's cookbook: https://github.com/opscode-cookbooks/chef-splunk
conflicts        'chef-splunk'
# BestBuy's cookbook: https://github.com/bestbuycom/splunk_cookbook
conflicts        'splunk'
# Cerner Aeon Cookbooks
conflicts        'splunk_server'
conflicts        'splunk_forwarder'
