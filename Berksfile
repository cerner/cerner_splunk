source 'https://supermarket.chef.io'

metadata

case RUBY_VERSION
when '2.1.6'
  # build-essential >=8.0.0 requires chef 12.5+
  cookbook 'build-essential', '< 8.0.0'
end

cookbook 'cerner_splunk_test', path: 'spec/cookbooks/cerner_splunk_test'
