# coding: UTF-8

name 'splunk_forwarder_vagrant'

run_list 'recipe[splunk_forwarder]',
         'recipe[splunk_forwarder::deploy_server]',
         'recipe[splunk_forwarder::chef_client]'

default_attributes(
  splunk: {
    deploy_server: '33.33.33.20:8089',
    forwarding_server: '33.33.33.20'
  }
)
