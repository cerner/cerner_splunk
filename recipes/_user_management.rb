# coding: UTF-8

# Cookbook Name:: cerner_splunk
# Recipe:: _user_management
#
# Manages the attributes of the splunk user. Called after package installation.

# User management currently not supported on windows
return if platform_family?('windows')

# user should be created by the package install
user node['splunk']['user'] do
  manage_home true
  action %i[create lock]
end

conflicts = node['splunk']['groups'].find_all do |group_to_add|
  node['splunk']['exclude_groups'].include?(group_to_add)
end

fail "You're asking us to both add and remove the #{node['splunk']['user']} user from: #{conflicts.join(',')} groups. Check your node['splunk']['groups'] attribute!" unless conflicts.empty?
fail "You cannot exclude the #{node['splunk']['user']} user from the #{node['splunk']['group']} group." if node['splunk']['exclude_groups'].include?(node['splunk']['group'])

groups_to_add = [node['splunk']['group']] + node['splunk']['groups']

groups_to_add.uniq.each do |grp|
  group "#{node['splunk']['user']}_#{grp}" do
    append true
    group_name grp
    members [node['splunk']['user']]
    action :manage
    notifies :touch, 'file[splunk-marker]', :immediately
  end
end

# Chef versions less than 11.10 do not support removing users from groups
# But if you're on a new enough version, we can take advantage of this functionality
if Chef::Resource::Group.instance_methods.include?(:excluded_members)
  node['splunk']['exclude_groups'].uniq.each do |grp|
    group "#{node['splunk']['user']}_#{grp}" do
      append true
      group_name grp
      excluded_members [node['splunk']['user']]
      action :manage
      notifies :touch, 'file[splunk-marker]', :immediately
    end
  end
else
  Chef::Log.info "This version of Chef client does not support removing users from groups. If you need to remove '#{node['splunk']['user']}' from groups you must do so manually."
end

# We need to run the recipe so that it fixes debian systems
include_recipe 'ulimit'

user_ulimit node['splunk']['user'] do
  filehandle_limit node['splunk']['limits']['open_files']
end
