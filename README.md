# vagrant-puppet-barman

An example of usage of the `barman::autoconfigure` class to setup
a Barman server taking regular backups of a PostgreSQL server.

## Dependencies

* Virtualbox
* Vagrant
* Ruby >= 1.9
* Puppet
* librarian-puppet

## Instructions

In the project directory, install the required Puppet modules running:

```
$ librarian-puppet install --verbose
```

Bring up and provision the Vagrant machines:

```
$ vagrant up
$ vagrant provision
$ vagrant provision
```
