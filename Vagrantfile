# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'socket'

# rubocop:disable RescueModifier
@internal = !Socket.gethostbyname('repo.release.cerner.corp').nil? rescue false
# rubocop:enable RescueModifier

Vagrant.require_version '>= 1.4.1'

%w(vagrant-omnibus).each do |plugin|
  fail "Missing #{plugin}. Please install it!" unless Vagrant.has_plugin? plugin
end

@boxes =
  if @internal
    {
      newest: { box: 'rhel65-1.0.1', box_url: 'http://repo.release.cerner.corp/nexus/content/repositories/vagrant/com/cerner/vagrant/rhel65/1.0.1/rhel65-1.0.1.box' },
      previous: { box: 'rhel64-1.2.1', box_url: 'http://repo.release.cerner.corp/nexus/content/repositories/vagrant/com/cerner/vagrant/rhel64/1.2.1/rhel64-1.2.1.box' },
      rhel55: { box: 'rhel55-1.0.0', box_url: 'http://repo.release.cerner.corp/nexus/content/repositories/vagrant/com/cerner/vagrant/rhel55/1.0.0/rhel55-1.0.0.box' },
      win2012r2: { box: 'win2012r2-standard-nocm-1.0.0', box_url: 'http://repo.release.cerner.corp/nexus/content/repositories/vagrant/com/cerner/vagrant/win2012r2-standard-nocm/1.0.0/win2012r2-standard-nocm-1.0.0.box' },
      ubuntu1204: { box: 'opscode_ubuntu-12.04_provisionerless', box_url: 'http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-12.04_chef-provisionerless.box' }
    }
  else
    {
      newest: { box: 'opscode_centos-7.0_provisionerless', box_url: 'http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_centos-7.0_chef-provisionerless.box' },
      previous: { box: 'opscode_centos-6.5_provisionerless', box_url: 'http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_centos-6.5_chef-provisionerless.box' },
      ubuntu1204: { box: 'opscode_ubuntu-12.04_provisionerless', box_url: 'http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-12.04_chef-provisionerless.box' }
    }
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
  f_default:    { ip: '33.33.33.50', hostname: 'default.forward', ports: { 9090 => 8089 } },
  f_debian:     { ip: '33.33.33.51', hostname: 'debian.forward', ports: { 9091 => 8089 } },
  f_old:        { ip: '33.33.33.52', hostname: 'splunk4.forward', ports: { 9092 => 8089 } },
  f_win2012r2:  { ip: '33.33.33.53', hostname: 'windowsforward', ports: { 9093 => 8089 } }
}

@chefip = @network[:chef][:ip]

# Network sanity checks.
fail 'Non-unique ips' if @network.collect { |_, v| v[:ip] }.uniq!

fail 'Non-unique hostnames' if @network.collect { |_, v| v[:hostname] }.uniq!

fail 'Non-unique ports' if @network.collect { |_, v| v[:ports].keys }.flat_map { |v| v }.uniq!

def default_omnibus(config)
  config.omnibus.chef_version = :latest
end

def disk(config)
  default_omnibus config
  config.vm.provision :shell, inline: 'lvextend -L 10G /dev/vg00/optlv00 && resize2fs /dev/vg00/optlv00 || echo "already resized"'
end

def network(config, name, splunk_password = true)
  net = @network.delete(name)
  throw "Unknown or duplicate config #{name}" unless net

  config.vm.hostname = "#{net[:hostname]}"
  config.vm.network :private_network, ip: net[:ip]
  net[:ports].each do |hostport, guestport|
    config.vm.network :forwarded_port, guest: guestport, host: hostport, auto_correct: true
  end

  config.berkshelf.enabled = false if Vagrant.has_plugin? 'vagrant-berkshelf'

  config.vm.provision :shell, inline: 'cat /etc/splunk/password; echo' if splunk_password
end

def set_box(config, name)
  config.vm.box = @boxes[name][:box]
  config.vm.box_url = @boxes[name][:box_url]
end

def chef_defaults(chef, name, environment = 'splunk_server')
  chef.environment = environment
  chef.chef_server_url = "http://#{@chefip}:4000/"
  chef.validation_key_path = 'vagrant_repo/fake-key.pem'
  chef.client_key_path = "/vagrant/vagrant_repo/pems/#{name}.pem"
  chef.node_name = name.to_s
  chef.encrypted_data_bag_secret_key_path = 'vagrant_repo/encrypted_data_bag_secret'
  # Switch roles only when you have setup local package mirroring per the Readme.
  chef.add_role 'splunk_mirrors_cerner' if @internal
  # chef.add_role 'splunk_mirrors_local'
  chef.add_role 'splunk_monitors'
end

Vagrant.configure('2') do |config|
  set_box config, :newest

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

    cfg.vm.provision :shell, inline: <<-'SCRIPT'.gsub(/^\s+/, '')
      yum -y install git
      rpm -q chefdk || rpm -Uvh https://opscode-omnibus-packages.s3.amazonaws.com/el/6/x86_64/chefdk-0.4.0-1.x86_64.rpm
    SCRIPT

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
      find roles/ -iname *.rb -exec knife role from file {} \;
      find environments/ -iname *.rb -exec knife environment from file {} \;
      berks install -b ../Berksfile
      berks upload -b ../Berksfile --no-freeze
      find . -name 'Berksfile*' -not -name '*.lock' -exec berks install -b {} \;
      find . -name 'Berksfile*' -not -name '*.lock' -exec berks upload -b {} --no-freeze \;
    SCRIPT

    if ENV['KNIFE_ONLY']
      cfg.vm.provision :shell, inline: 'cd /vagrant/vagrant_repo; mv .nodes.bak nodes', privileged: false
    end

    cfg.vm.provision :shell, inline: <<-'SCRIPT'.gsub(/^\s+/, ''), privileged: false
      mkdir -p "$HOME/app_service"
      rm -rf "$HOME/app_service/*"
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
      nohup /opt/chefdk/embedded/bin/ruby -run -e httpd "$HOME/app_service" -p5000 2>&1 > /dev/null &
      sleep 10
    SCRIPT

    network cfg, :chef, false
  end

  config.vm.define :s_license do |cfg|
    disk(cfg)
    cfg.vm.provision :chef_client do |chef|
      chef_defaults chef, :s_license, 'splunk_license'
      chef.add_recipe 'cerner_splunk::license_server'
    end
    network cfg, :s_license
  end

  config.vm.define :c1_master do |cfg|
    disk(cfg)
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
      disk(cfg)
      cfg.vm.provider :virtualbox do |vb|
        vb.customize ['modifyvm', :id, '--memory', 256]
      end
      cfg.vm.provision :chef_client do |chef|
        chef_defaults chef, symbol
        chef.add_recipe 'cerner_splunk::cluster_slave'
      end
      network cfg, symbol
    end
  end

  config.vm.define :c1_search do |cfg|
    disk(cfg)
    cfg.vm.provider :virtualbox do |vb|
      vb.customize ['modifyvm', :id, '--memory', 256]
    end
    cfg.vm.provision :chef_client do |chef|
      chef_defaults chef, :c1_search
      chef.add_recipe 'cerner_splunk::search_head'
    end
    network cfg, :c1_search
  end

  config.vm.define :s_standalone do |cfg|
    disk(cfg)
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
    set_box cfg, :previous
    cfg.vm.provision :chef_client do |chef|
      chef_defaults chef, :f_default, 'splunk_standalone'
      chef.add_recipe 'cerner_splunk'
      chef.add_recipe 'cerner_splunk_test'
    end
    network cfg, :f_default
  end

  config.vm.define :f_debian do |cfg|
    default_omnibus config
    set_box cfg, :ubuntu1204
    cfg.vm.provider :virtualbox do |vb|
      vb.customize ['modifyvm', :id, '--memory', 256]
    end
    cfg.vm.provision :chef_client do |chef|
      chef_defaults chef, :f_debian, 'splunk_standalone'
      chef.add_recipe 'cerner_splunk'
    end
    network cfg, :f_debian
  end

  config.vm.define :f_old do |cfg|
    set_box cfg, :rhel55
    cfg.omnibus.chef_version = '10.24.0'
    cfg.vm.provision :chef_client do |chef|
      chef_defaults chef, :f_old, '_default'
      chef.add_role 'splunk_forwarder_vagrant'
    end unless ENV['RELOAD']
    cfg.vm.provision :chef_client do |chef|
      chef_defaults chef, :f_old, '_default'
      chef.add_role 'splunk_forwarder_vagrant_new'
      chef.add_recipe 'cerner_splunk_test'
    end
    network cfg, :f_old
  end if @internal

  config.vm.define :f_win2012r2 do |cfg|
    set_box cfg, :win2012r2
    default_omnibus config
    cfg.vm.provider :virtualbox do |vb|
      vb.customize ['modifyvm', :id, '--memory', 1024]
    end
    cfg.vm.provision :chef_client do |chef|
      chef_defaults chef, :f_win2012r2, 'splunk_standalone'
      chef.add_role 'splunk_monitors_windows'
      chef.add_recipe 'cerner_splunk'
    end
    network cfg, :f_win2012r2, false
  end if @internal
end
