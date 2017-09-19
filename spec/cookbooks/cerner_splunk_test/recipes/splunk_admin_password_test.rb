# frozen_string_literal: true

params = node['test_parameters'].to_hash

splunk_admin_password 'update admin password' do
  params.each { |prop, val| send(prop, val) }
end
