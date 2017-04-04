# coding: UTF-8

# Cookbook Name:: cerner_splunk_test
# Recipe:: default
#
# Invokes the LWRP of the cerner_splunk Cookbook

directory '/testlogs' do
  owner 'vagrant'
  group 'vagrant'
  mode '0750'
end

%w[one two three four].each do |dir|
  directory "/testlogs/#{dir}" do
    owner 'vagrant'
    group 'vagrant'
    mode '0750'
  end
  (1..3).each do |i|
    template "/testlogs/#{dir}/access#{i}.log" do
      backup false
      source 'access.log.erb'
      owner 'vagrant'
      group 'vagrant'
      mode '0640'
    end
  end
end

splunk_forwarder_monitors 'foo' do
  index 'pop_health'
  monitors [{
    path: '/testlogs/two/access1.log',
    sourcetype: 'access_combined',
    index: 'bobs_index_emporium'
  }]
end

cerner_splunk_forwarder_monitors 'bar' do
  index 'pop_health'
  monitors [{
    path: '/testlogs/one/*.log',
    sourcetype: 'access_combined'
  }]
end

cerner_splunk_test_lwrp 'baz' do
  monitors [{
    path: '/testlogs/three/access2.log',
    sourcetype: 'access_combined'
  }, {
    path: '/testlogs/four/access3.log',
    sourcetype: 'access_combined',
    index: 'bobs_index_emporium'
  }]
end
