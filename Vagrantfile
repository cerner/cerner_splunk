# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.require_version '>= 1.4.1'

%w[vagrant-ohai vagrant-omnibus].each do |plugin|
  fail "Missing #{plugin}. Please install it!" unless Vagrant.has_plugin? plugin
end

@network = {
  chef:         { ip: '33.33.33.33', hostname: 'chef', ports: { 4000 => 4000 } },
  c1_search:    { ip: '33.33.33.10', hostname: 'search.splunk', ports: { 8001 => 8000, 8091 => 8089 } },
  c1_master:    { ip: '33.33.33.11', hostname: 'master.splunk', ports: { 8002 => 8000, 8092 => 8089 } },
  c1_slave1:    { ip: '33.33.33.12', hostname: 'slave01.splunk', ports: { 8003 => 8000, 8093 => 8089 } },
  c1_slave2:    { ip: '33.33.33.13', hostname: 'slave02.splunk', ports: { 8004 => 8000, 8094 => 8089 } },
  c1_slave3:    { ip: '33.33.33.14', hostname: 'slave03.splunk', ports: { 8005 => 8000, 8095 => 8089 } },
  s_standalone: { ip: '33.33.33.20', hostname: 'splunk2', ports: { 8006 => 8000, 8096 => 8089 } },
  s_license:    { ip: '33.33.33.30', hostname: 'splunk-license', ports: { 8007 => 8000, 8097 => 8089 } },
  c2_boot1:     { ip: '33.33.33.15', hostname: 'search01.splunk', ports: { 8008 => 8000, 8098 => 8089 } },
  c2_boot2:     { ip: '33.33.33.16', hostname: 'search02.splunk', ports: { 8009 => 8000, 8099 => 8089 } },
  c2_captain:   { ip: '33.33.33.17', hostname: 'search03.splunk', ports: { 8010 => 8000, 8100 => 8089 } },
  c2_newnode:   { ip: '33.33.33.18', hostname: 'search04.splunk', ports: { 8011 => 8000, 8101 => 8089 } },
  c2_deployer:  { ip: '33.33.33.28', hostname: 'deployer.splunk', ports: { 8012 => 8000, 8102 => 8089 } },
  s1_slave1:    { ip: '33.33.33.31', hostname: 's1.slave01.splunk', ports: { 8013 => 8000, 8103 => 8089 } },
  s1_slave2:    { ip: '33.33.33.32', hostname: 's1.slave02.splunk', ports: { 8014 => 8000, 8104 => 8089 } },
  s1_slave3:    { ip: '33.33.33.34', hostname: 's1.slave03.splunk', ports: { 8015 => 8000, 8105 => 8089 } },
  s1_master:    { ip: '33.33.33.35', hostname: 's1.master.splunk', ports: { 8016 => 8000, 8106 => 8089 } },
  s2_search:    { ip: '33.33.33.36', hostname: 's2.search.splunk', ports: { 8017 => 8000, 8107 => 8089 } },
  s2_slave1:    { ip: '33.33.33.37', hostname: 's2.slave01.splunk', ports: { 8018 => 8000, 8108 => 8089 } },
  s2_slave2:    { ip: '33.33.33.38', hostname: 's2.slave02.splunk', ports: { 8019 => 8000, 8109 => 8089 } },
  f_default:    { ip: '33.33.33.50', hostname: 'default.forward', ports: { 9090 => 8089 } },
  f_debian:     { ip: '33.33.33.51', hostname: 'debian.forward', ports: { 9091 => 8089 } },
  f_heavy:      { ip: '33.33.33.52', hostname: 'heavy.forward', ports: { 9092 => 8089 } },
  f_win2012r2:  { ip: '33.33.33.53', hostname: 'windowsforward', ports: { 9093 => 8089 } }
}

@chefip = @network[:chef][:ip]

# Network sanity checks.
fail 'Non-unique ips' if @network.collect { |_, v| v[:ip] }.uniq!

fail 'Non-unique hostnames' if @network.collect { |_, v| v[:hostname] }.uniq!

fail 'Non-unique ports' if @network.collect { |_, v| v[:ports].keys }.flat_map { |v| v }.uniq!

def default_omnibus(config)
  config.omnibus.chef_version = '12'
end

def network(config, name, splunk_password = true)
  net = @network.delete(name)
  throw "Unknown or duplicate config #{name}" unless net

  config.vm.hostname = net[:hostname]
  config.vm.network :private_network, ip: net[:ip]
  net[:ports].each do |hostport, guestport|
    config.vm.network :forwarded_port, guest: guestport, host: hostport, auto_correct: true
  end

  config.berkshelf.enabled = false if Vagrant.has_plugin? 'vagrant-berkshelf'

  config.vm.provision :shell, inline: 'cat /etc/splunk/password; echo' if splunk_password
end

def chef_defaults(chef, name, environment = 'splunk_server')
  chef.environment = environment
  chef.chef_server_url = "http://#{@chefip}:4000/"
  chef.validation_key_path = 'vagrant_repo/fake-key.pem'
  chef.client_key_path = "/vagrant/vagrant_repo/pems/#{name}.pem"
  chef.node_name = name.to_s
  chef.encrypted_data_bag_secret_key_path = 'vagrant_repo/encrypted_data_bag_secret'
  # Use this role only when you have setup local package mirroring per the readme.
  # chef.add_role 'splunk_mirrors_local'
  chef.add_role 'splunk_monitors'
end

Vagrant.configure('2') do |config|
  config.vm.box = 'bento/centos-6.7'
  config.ohai.primary_nic = 'eth1'

  if Vagrant.has_plugin? 'vagrant-berkshelf'
    config.berkshelf.enabled = false
    # https://github.com/berkshelf/vagrant-berkshelf/issues/180
    config.berkshelf.berksfile_path = 'this_is_a_deprecated_plugin_and_i_do_not_want_to_use_it'
  end

  config.vm.provider :virtualbox do |vb|
    vb.customize ['modifyvm', :id, '--natdnsproxy1', 'off']
    vb.customize ['modifyvm', :id, '--natdnshostresolver1', 'off']
    vb.customize ['modifyvm', :id, '--memory', 128]
  end

  config.vm.define :chef do |cfg|
    config.omnibus.chef_version = nil

    cfg.vm.provision :shell, inline: 'rpm -q chefdk || curl -L https://omnitruck.chef.io/install.sh | bash -s -- -P chefdk'

    if ENV['KNIFE_ONLY']
      cfg.vm.provision :shell, inline: 'cd /vagrant/vagrant_repo; mv nodes .nodes.bak', privileged: false
    else
      cfg.vm.provision :shell, inline: 'kill -9 $(ps f -fA | grep [c]hef-zero | awk \'{print $2}\'); echo "killed chef-zero"', privileged: false
    end
    # knife upload will take care of json files,
    # We then need to run through any ruby files as well
    # We use berks to upload everything here as well, as we could be on VPN :)
    cfg.vm.provision :shell, inline: <<-'SCRIPT'.gsub(/^\s+/, ''), privileged: false
      export PATH=$PATH:/opt/chefdk/bin:/opt/chefdk/embedded/bin
      nohup chef-zero -H 0.0.0.0 -p 4000 2>&1 > /dev/null &
      cd /vagrant/vagrant_repo
      knife upload .
      berks install -b ../Berksfile
      berks upload -b ../Berksfile --no-freeze
    SCRIPT

    if ENV['KNIFE_ONLY']
      cfg.vm.provision :shell, inline: 'cd /vagrant/vagrant_repo; mv .nodes.bak nodes', privileged: false
    end

    app_gen = <<-'SCRIPT'.gsub(/^\s+/, '')
      mkdir -p "$HOME/app_service"
      rm -rf "$HOME/app_service/*"
      cd /vagrant/vagrant_repo/files
      cp -R lookups "$HOME/app_service/"
      cd /vagrant/vagrant_repo/apps
      timestamp=`date -u +%Y%m%d%H%M%S`
      for D in *; do
        if [ -d "${D}" ]; then
          if [ -f "${D}/default/app.conf" ]; then
            cp "${D}/default/app.conf" "app.conf.bak"
            sed -i "s/^\(version \?= \?.\+ SNAPSHOT\)$/\1_`echo $timestamp`/" "${D}/default/app.conf"
          fi
          tar czf "$HOME/app_service/$D.tgz" "$D"
          [ -f "app.conf.bak" ] && mv "app.conf.bak" "${D}/default/app.conf"
        fi
      done
      cd "$HOME"
      netstat -nl | grep -q :5000 || nohup /opt/chefdk/embedded/bin/ruby -run -e httpd "$HOME/app_service" -p5000 2>&1 > /dev/null &
      sleep 10
    SCRIPT

    app_gen.sub!('tar', '[ -f "$HOME/app_service/$D.tgz" ] || tar') unless ENV['REGEN_APPS']

    cfg.vm.provision :shell, inline: app_gen, privileged: false

    network cfg, :chef, false
  end

  config.vm.define :s_license do |cfg|
    default_omnibus config
    cfg.vm.provision :chef_client do |chef|
      chef_defaults chef, :s_license, 'splunk_license'
      chef.add_recipe 'cerner_splunk::license_server'
    end
    network cfg, :s_license
  end

  config.vm.define :c1_master do |cfg|
    default_omnibus config
    cfg.vm.provision :chef_client do |chef|
      chef_defaults chef, :c1_master
      chef.add_recipe 'cerner_splunk::cluster_master'
    end
    network cfg, :c1_master
  end

  # Cruisin' Mos Espa In my Delorean ...
  (1..3).each do |n|
    symbol = "c1_slave#{n}".to_sym
    config.vm.define symbol do |cfg|
      default_omnibus config
      cfg.vm.provider :virtualbox do |vb|
        vb.customize ['modifyvm', :id, '--memory', 256]
      end
      cfg.vm.provision :chef_client do |chef|
        chef_defaults chef, symbol
        chef.add_recipe 'cerner_splunk::cluster_slave'
        # Uncomment the line below to set predefined GUIDs on the cluster slaves (for playing with license pooling)
        # chef.add_recipe 'cerner_splunk_test::configure_guids'
      end
      network cfg, symbol
    end
  end

  config.vm.define :s1_master do |cfg|
    default_omnibus config
    cfg.vm.provision :chef_client do |chef|
      chef_defaults chef, :s1_master, 'splunk_site1'
      chef.add_recipe 'cerner_splunk::cluster_master'
    end
    network cfg, :s1_master
  end

  (1..3).each do |n|
    symbol = "s1_slave#{n}".to_sym
    config.vm.define symbol do |cfg|
      default_omnibus config
      cfg.vm.provider :virtualbox do |vb|
        vb.customize ['modifyvm', :id, '--memory', 256]
      end
      cfg.vm.provision :chef_client do |chef|
        chef_defaults chef, symbol, 'splunk_site1'
        chef.add_recipe 'cerner_splunk::cluster_slave'
      end
      network cfg, symbol
    end
  end

  (1..2).each do |n|
    symbol = "s2_slave#{n}".to_sym
    config.vm.define symbol do |cfg|
      default_omnibus config
      cfg.vm.provider :virtualbox do |vb|
        vb.customize ['modifyvm', :id, '--memory', 256]
      end
      cfg.vm.provision :chef_client do |chef|
        chef_defaults chef, symbol, 'splunk_site2'
        chef.add_recipe 'cerner_splunk::cluster_slave'
      end
      network cfg, symbol
    end
  end

  config.vm.define :s2_search do |cfg|
    default_omnibus config
    cfg.vm.provider :virtualbox do |vb|
      vb.customize ['modifyvm', :id, '--memory', 256]
    end
    cfg.vm.provision :chef_client do |chef|
      chef_defaults chef, :s2_search, 'splunk_site2'
      chef.add_recipe 'cerner_splunk::search_head'
    end
    network cfg, :s2_search
  end

  config.vm.define :c1_search do |cfg|
    default_omnibus config
    cfg.vm.provider :virtualbox do |vb|
      vb.customize ['modifyvm', :id, '--memory', 256]
    end
    cfg.vm.provision :chef_client do |chef|
      chef_defaults chef, :c1_search
      chef.add_recipe 'cerner_splunk::search_head'
    end
    network cfg, :c1_search
  end

  (1..2).each do |n|
    symbol = "c2_boot#{n}".to_sym
    config.vm.define symbol do |cfg|
      default_omnibus config
      cfg.vm.provider :virtualbox do |vb|
        vb.customize ['modifyvm', :id, '--memory', 256]
      end
      cfg.vm.provision :chef_client do |chef|
        chef_defaults chef, symbol
        chef.add_recipe 'cerner_splunk::shc_search_head'
        chef.json = {
          'splunk' => {
            'bootstrap_shc_member' => true
          }
        }
      end
      network cfg, symbol
    end
  end

  config.vm.define :c2_captain do |cfg|
    default_omnibus config
    cfg.vm.provider :virtualbox do |vb|
      vb.customize ['modifyvm', :id, '--memory', 256]
    end
    cfg.vm.provision :chef_client do |chef|
      chef_defaults chef, :c2_captain
      chef.add_recipe 'cerner_splunk::shc_captain'
    end
    network cfg, :c2_captain
  end

  config.vm.define :c2_deployer do |cfg|
    default_omnibus config
    cfg.vm.provider :virtualbox do |vb|
      vb.customize ['modifyvm', :id, '--memory', 256]
    end
    cfg.vm.provision :chef_client do |chef|
      chef_defaults chef, :c2_deployer
      chef.add_recipe 'cerner_splunk::shc_deployer'
    end
    network cfg, :c2_deployer
  end

  config.vm.define :c2_newnode do |cfg|
    default_omnibus config
    cfg.vm.provider :virtualbox do |vb|
      vb.customize ['modifyvm', :id, '--memory', 256]
    end
    cfg.vm.provision :chef_client do |chef|
      chef_defaults chef, :c2_newnode
      chef.add_recipe 'cerner_splunk::shc_search_head'
    end
    network cfg, :c2_newnode
  end

  config.vm.define :s_standalone do |cfg|
    default_omnibus config
    cfg.vm.provider :virtualbox do |vb|
      vb.customize ['modifyvm', :id, '--memory', 256]
    end
    cfg.vm.provision :chef_client do |chef|
      chef_defaults chef, :s_standalone, 'splunk_standalone'
      chef.add_recipe 'cerner_splunk::server'
    end
    network cfg, :s_standalone
  end

  config.vm.define :f_default do |cfg|
    default_omnibus config
    cfg.vm.provision :chef_client do |chef|
      chef_defaults chef, :f_default, 'splunk_standalone'
      chef.add_recipe 'cerner_splunk'
      chef.add_recipe 'cerner_splunk_test'
    end
    network cfg, :f_default
  end

  config.vm.define :f_debian do |cfg|
    default_omnibus config
    cfg.vm.box = 'bento/ubuntu-12.04'
    cfg.vm.provider :virtualbox do |vb|
      vb.customize ['modifyvm', :id, '--memory', 256]
    end
    cfg.vm.provision :chef_client do |chef|
      chef_defaults chef, :f_debian, 'splunk_standalone'
      chef.add_recipe 'cerner_splunk'
    end
    network cfg, :f_debian
  end

  config.vm.define :f_heavy do |cfg|
    default_omnibus config
    cfg.vm.provision :chef_client do |chef|
      chef_defaults chef, :f_heavy, 'splunk_standalone'
      chef.add_recipe 'cerner_splunk::heavy_forwarder'
    end
    network cfg, :f_heavy
  end

  config.vm.define :f_win2012r2 do |cfg|
    cfg.vm.box = 'opentable/win-2012r2-standard-amd64-nocm'
    # Without the line below here or in the box, vagrant-omnibus breaks on windows.
    # Reference: https://github.com/chef/vagrant-omnibus/issues/90#issuecomment-51816397
    cfg.vm.guest = :windows
    default_omnibus config
    # config below prevents the installation of latest Chef on the box.
    # Reference: https://github.com/chef/vagrant-omnibus/issues/118
    config.omnibus.install_url = 'https://packages.chef.io/files/stable/chef/12.18.31/windows/2012r2/chef-client-12.18.31-1-x64.msi'
    cfg.vm.provider :virtualbox do |vb|
      vb.customize ['modifyvm', :id, '--memory', 1024]
    end
    cfg.vm.provision :chef_client do |chef|
      chef_defaults chef, :f_win2012r2, 'splunk_standalone'
      chef.add_role 'splunk_monitors_windows'
      chef.add_recipe 'cerner_splunk'
    end
    network cfg, :f_win2012r2, false
  end
end
