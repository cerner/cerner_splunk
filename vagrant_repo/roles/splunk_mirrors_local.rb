# coding: UTF-8

name 'splunk_mirrors_local'

description 'Configures mirrors for Splunk 4 & 6'

override_attributes(
  splunk: {
    forwarder_root: 'http://10.0.2.2:8080/releases',
    package: {
      base_url: 'http://10.0.2.2:8080/releases'
    }
  }
)
