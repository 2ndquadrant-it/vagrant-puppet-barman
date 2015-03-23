# Puppet Master
node puppet {
  @@host { 'puppetmaster_host':
    ensure       => 'present',
    name         => $::fqdn,
    host_aliases => $::hostname,
    ip           => '192.168.56.220',
  }
  @@sshkey { "${::hostname}_ecdsa":
    host_aliases => [ $::hostname, $::fqdn ],
    type         => 'ecdsa-sha2-nistp256',
    key          => $::sshecdsakey,
  }

  # Collect:
  Host <<| |>>
  Sshkey <<| |>>

  # Setup PuppetDB
  class { 'puppetdb': }->
  # Setup Puppet Master, Apache and Passenger
  class { 'puppet::master':
    storeconfigs => true,
    autosign     => true,
    environments => 'directory',
  }->

  # Configure Puppet Agent
  class { 'puppet::agent':
    puppet_run_style => 'cron',
    puppet_server    => 'puppet.local.lan',
    environment      => 'production',
  }->

  # Have the manifest and the modules available for the master to distribute
  file {
    ['/etc/puppet/environments', '/etc/puppet/environments/production']:
      ensure => directory;
    '/etc/puppet/environments/production/modules':
      ensure => 'link',
      target => '/vagrant/modules';
    '/etc/puppet/environments/production/manifests':
      ensure => 'link',
      target => '/vagrant/manifests';
  }

}

node backup {

  @@host { 'backup_host':
    ensure       => 'present',
    name         => $::fqdn,
    host_aliases => $::hostname,
    ip           => '192.168.56.222',
  }

  @@sshkey { "${::hostname}_ecdsa":
    host_aliases => [ $::hostname, $::fqdn ],
    type         => 'ecdsa-sha2-nistp256',
    key          => $::sshecdsakey,
  }

  # Collect:
  Host <<| |>>
  Sshkey <<| |>>

  # Configure the Puppet Agent
  class { 'puppet::agent':
    puppet_run_style => 'cron',
    puppet_server    => 'puppet.local.lan',
    environment      => 'production',
  }->

  class { 'barman':
    autoconfigure      => true,
    exported_ipaddress => '192.168.56.222/32',
  }

}

node pg {

  @@host { 'pg_host':
    ensure       => 'present',
    name         => $::fqdn,
    host_aliases => $::hostname,
    ip           => '192.168.56.221',
  }

  @@sshkey { "${::hostname}_ecdsa":
    host_aliases => [ $::hostname, $::fqdn ],
    type         => 'ecdsa-sha2-nistp256',
    key          => $::sshecdsakey,
  }

  # Collect:
  Host <<| |>>
  Sshkey <<| |>>

  # Configure the Puppet Agent
  class { 'puppet::agent':
    puppet_run_style => 'cron',
    puppet_server    => 'puppet.local.lan',
    environment      => 'production',
  }->

  # Configure PostgreSQL
  class { 'postgresql::server':
    listen_addresses     => '*',
  }

  # Export the parameters required by Barman
  class { 'barman::postgres':
    retention_policy        => 'RECOVERY WINDOW OF 1 WEEKS',
    minimum_redundancy      => 1,
    last_backup_maximum_age => '2 WEEKS',
    reuse_backup            => 'link',
    backup_hour             => 1,
    backup_minute           => 0,
  }
}

