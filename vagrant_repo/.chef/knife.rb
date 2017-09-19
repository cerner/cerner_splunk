# frozen_string_literal: true

alternate_node = ENV['node']

current_path = Pathname.new(__FILE__).dirname
log_level       :info
log_location    STDOUT
node_name       alternate_node.nil? ? 'knife_workstation' : alternate_node
client_key      alternate_node.nil? ? current_path.parent.join('fake-key.pem').to_s : current_path.parent.join('pems').join("#{alternate_node}.pem").to_s
chef_server_url 'http://127.0.0.1:4000'
chef_repo_path  current_path.parent.to_s
