# Puppet Master
node puppet {

  # Install puppetserver and start the service
  package {'puppetserver':
    ensure => 'present',
  }->
  exec { 'fix certificates bug':
    unless  => 'test -f /etc/puppetlabs/puppet/ssl/certs/puppet.local.lan.pem',
    command => 'service puppetserver stop; rm -rf /etc/puppetlabs/puppet/ssl/*; service puppetserver start',
    cwd     => '/etc/puppetlabs/puppet/ssl/',
    path    => '/bin:/usr/sbin:/usr/bin',
  }->
  # Enable autosign for all nodes in local.lan network
  file { '/etc/puppetlabs/puppet/autosign.conf':
    ensure  => present,
    content => '*.local.lan',
    mode    => '0644',
    notify  => Service['puppetserver'],
    require => Package['puppetserver'],
  }->
  # Link to the directory with the puppet manifests
  file {
    '/etc/puppetlabs/code/environments':
      ensure => directory;
    '/etc/puppetlabs/code/environments/production':
      ensure => 'link',
      target => '/vagrant/environments/production',
      force  => true;
  }->
  # Start puppetserver
  service {'puppetserver':
    enable => true,
    ensure => 'running',
  }


  # Configure puppetdb and its underlying database
  class { 'puppetdb': }
  # Configure the Puppet master to use puppetdb
  class { 'puppetdb::master::config': }
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

  class { 'barman':
    autoconfigure       => true,
    exported_ipaddress  => '192.168.56.222/32',
    manage_package_repo => true,
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

  # Configure PostgreSQL
  class { 'postgresql::server':
    listen_addresses     => '*',
  }

  # Export the parameters required by Barman
  class { 'barman::postgres':
    retention_policy        => 'RECOVERY WINDOW OF 1 WEEK',
    minimum_redundancy      => 1,
    last_backup_maximum_age => '1 WEEK',
    reuse_backup            => 'link',
    backup_hour             => 1,
    backup_minute           => 0,
}
}

