# frozen_string_literal: true

# Cookbook Name:: cerner_splunk
# Provider:: sh_cluster
#

provides :sh_cluster if respond_to?(:provides)

action :initialize do
  search_heads = new_resource.search_heads
  admin_password = new_resource.admin_password

  execute 'Captain assignment' do # ~FC009
    command "#{node['splunk']['cmd']} bootstrap shcluster-captain -servers_list '#{search_heads.join(',')}' -auth admin:#{admin_password}"
    environment 'HOME' => node['splunk']['home']
    # execute only if there isn't a captain in the cluster
    not_if "#{node['splunk']['cmd']} list shcluster-members -auth admin:#{admin_password} | grep is_captain:1"
    sensitive true
  end
end

action :add do
  search_heads = new_resource.search_heads
  admin_password = new_resource.admin_password
  management_host = CernerSplunk.management_host(node)

  execute 'add search head' do # ~FC009
    command "#{node['splunk']['cmd']} add shcluster-member -current_member_uri #{search_heads.first} -auth admin:#{admin_password}"
    environment 'HOME' => node['splunk']['home']
    # execute only if this SH is not an existing member of the SHC
    not_if "#{node['splunk']['cmd']} list shcluster-members -auth admin:#{admin_password} | grep #{management_host}"
    ignore_failure true
    sensitive true
  end
end

action :remove do
  admin_password = new_resource.admin_password
  management_host = CernerSplunk.management_host(node)

  execute 'remove search head' do # ~FC009
    command "#{node['splunk']['cmd']} remove shcluster-member -auth admin:#{admin_password}"
    environment 'HOME' => node['splunk']['home']
    # execute only if this SH is an existing member of the SHC
    only_if "#{node['splunk']['cmd']} list shcluster-members -auth admin:#{admin_password} | grep #{management_host}"
    sensitive true
  end
end
