# coding: UTF-8

name 'splunk_forwarder_vagrant_new'

run_list 'recipe[cerner_splunk]'

default_attributes(
  splunk: {
    config: {
      clusters: [
        'cerner_splunk/cluster-standalone',
        'cerner_splunk/cluster-vagrant'
      ]
    }
  }
)
