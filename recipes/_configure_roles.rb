# coding: UTF-8
#
# Cookbook Name:: cerner_splunk
# Recipe:: _configure_roles
#
# Configures the roles available on the system

hash = CernerSplunk::DataBag.load node['splunk']['config']['roles'],
                                  pick_context: CernerSplunk.keys(node)

unless hash
  Chef::Log.info 'Roles not configured for this node.'
  return
end

user_prefs = {}
authorize = {}

hash.each do | stanza, values |
  pref_entries, auth_entries = values.inject([{}, {}]) do |result, (key, value)|
    prefs = result[0]
    auth = result[1]

    case key
    when 'tz', 'showWhatsNew'
      prefs[key] = value
    when 'app'
      prefs['default_namespace'] = value
    when 'capabilities'
      value.each do |cap|
        if cap.start_with? '!'
          cap[0] = ''
          auth[cap] = 'disabled'
        else
          auth[cap] = 'enabled'
        end
      end
    else
      if value.is_a? Array
        auth[key] = value.join(';')
      else
        auth[key] = value
      end
    end
    result
  end

  unless pref_entries.empty?
    pref_stanza = stanza == 'default' ? 'general_default' : "role_#{stanza}"
    user_prefs[pref_stanza] = pref_entries
  end

  if stanza == 'default'
    authorize['default'] = auth_entries unless auth_entries.empty?
  else
    authorize["role_#{stanza}"] = auth_entries
  end
end

authorize_action = authorize.empty? ? :delete : :create

splunk_template 'system/authorize.conf' do
  stanzas authorize
  action authorize_action
  notifies :restart, 'service[splunk]'
end

directory "#{node['splunk']['home']}/etc/apps/user-prefs/local" do
  user node['splunk']['user']
  group node['splunk']['group']
  mode '0700'
end

user_prefs_action = user_prefs.empty? ? :delete : :create

splunk_template 'apps/user-prefs/user-prefs.conf' do
  stanzas user_prefs
  action user_prefs_action
  notifies :restart, 'service[splunk]'
end
