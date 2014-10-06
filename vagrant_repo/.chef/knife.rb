# coding: UTF-8

current_dir = File.dirname(__FILE__)
log_level       :info
log_location    STDOUT
node_name       'knife_workstation'
client_key      "#{File.expand_path('..',current_dir)}/fake-key.pem"
chef_server_url 'http://127.0.0.1:4000'
chef_repo_path  "#{File.expand_path('..',current_dir)}"
