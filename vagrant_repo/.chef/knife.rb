# coding: UTF-8

alternate_node = ENV['node']

current_dir = File.dirname(__FILE__)
log_level       :info
log_location    STDOUT
node_name       alternate_node.nil? ? 'knife_workstation' : alternate_node
client_key      alternate_node.nil? ? "#{File.expand_path('..',current_dir)}/fake-key.pem" : "#{File.expand_path('..',current_dir)}/pems/#{alternate_node}.pem"
chef_server_url 'http://127.0.0.1:4000'
chef_repo_path  "#{File.expand_path('..',current_dir)}"
