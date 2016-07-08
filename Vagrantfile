# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  {
    :puppet => {
      :ip      => '192.168.56.220',
      :box     => 'ubuntu/trusty64',
      :role    => 'master'
    },
    :pg => {
      :ip      => '192.168.56.221',
      :box     => 'ubuntu/trusty64',
      :role    => 'agent'
    },
    :backup => {
      :ip      => '192.168.56.222',
      :box     => 'ubuntu/trusty64',
      :role    => 'agent'
    }
  }.each do |name,cfg|
    config.vm.define name do |local|
      local.vm.box = cfg[:box]
      local.vm.hostname = name.to_s + '.local.lan'
      local.vm.network :private_network, ip: cfg[:ip]
      family = 'ubuntu'
      bootstrap_url = 'https://raw.github.com/hashicorp/puppet-bootstrap/master/' + family + '.sh'

      # Run puppet-bootstrap and enable the Puppet agent
      local.vm.provision :shell, :inline => <<-eos
        if [ ! -e /var/tmp/.bash.provision.done ]; then
          echo "192.168.56.220  puppet.local.lan        puppet puppetdb puppetdb.local.lan" >> /etc/hosts
          curl -L #{bootstrap_url} | PUPPET_COLLECTION=pc1 bash
          puppet agent --enable
          touch /var/tmp/.bash.provision.done
        fi
      eos

      if cfg[:role] == 'master'
        # Puppet master needs more RAM
        local.vm.provider "virtualbox" do |v|
          v.memory = 4096
        end

        # Provision the master with Puppet
        local.vm.provision :puppet do |puppet|
          puppet.environment_path = "environments"
          puppet.options = [
           '--verbose',
          ]
        end
      end

      # Puppet agents should be provisioned by the master
      local.vm.provision :puppet_server do |puppet|
        puppet.options = [
         '--verbose',
        ]
      end
    end
  end
end

