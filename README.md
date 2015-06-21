# rsnapshot

#### Table of Contents

1. [Overview](#overview)
2. [Module Description](#module-description)
3. [Differences between this and other modules](#differences-between-this-and-other-modules)
4. [Setup - The basics of getting started with rsnapshot](#setup)
    * [What rsnapshot affects](#what-rsnapshot-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with rsnapshot](#beginning-with-rsnapshot)
5. [Usage - Configuration options and additional functionality](#usage)
    * [Configuring the Server](#configuring-the-server)
    * [Configuring the Client](#configuring-the-client)
    * [Adding Backup Points to Profiles](#adding-backup-points-to-profiles)
    * [Backing Up Machines Outside of Puppet](#backing-up-machines-outside-of-puppet)
6. [Reference](#reference)
    * [Public Classes](#public-classes)
    * [Defines](#public-defines)
    * [Private Classes](#private-classes)
    * [Private Defines](#private-defines)
7. [Resources](#resources)
    * [Define rsnapshot::backup](#[define-rsnapshotbackup)
    * [Class rsnapshot::client](#class-rsnapshotclient)
    * [Class rsnapshot::server](#class-rsnapshotserver)
    * [Define rsnapshot::server::config](#define-rsnapshotserverconfig)
8. [Development](#development)

## Overview

This module manages backups using rsnapshot.

## Module Description

> rsnapshot is a filesystem snapshot utility based on rsync. rsnapshot makes it
easy to make periodic snapshots of local machines, and remote machines over ssh.
The code makes extensive use of hard links whenever possible, to greatly reduce
the disk space required.

This module installs and configures the rsnapshot module, which is a backup tool
that utilizes rsync to create fast incremental backups as well as a hardlink
system which makes all incremental backups work as full ones.

This module makes it easy to manage a backup server based off of rsnapshot while
utilizing common Puppet patterns.

## Differences between this and other modules.

* **Client specific options instead of enforced globals.** Rather than rely on a
  single configuration file and monolithic backup runs this module uses stand
  along configurations for each host. Besides being more resilient to errors,
  this enables unique client settings- for instance, setting different retain
  settings for different hosts.

* **Support for SSH without root access.** In most cases root login is not
  available over ssh for security reasons, so this module relies instead on
  having it's own unique user with locked down sudo access to give it the needed
  access for backups.

* **Support for automatic key sharing.** The client machine will automatically
  receive the ssh key from the server that it is backing up to.

* **Locked down ssh accounts.** All ssh accounts are locked down. SSH keys can
  only by used by the single backup host, without access to features like x
  forwarding. Commands allowed by the ssh key are limited to specific wrapper
  scripts installed by this module.

* **Sender only rsync.** One of the biggest threats with rsync access is the
  potential to overwrite existing files on the system to gain unauthorized
  access. This module uses a wrapper script around rsync on the client side
  which limits it to only being able to send data, not write it.


## Setup

### What rsnapshot affects

* Installs rsync and rsnapshot on server machine.
* Installs rsync on client machine.
* Creates rsnapshot configuration files for each client on the server machine.
* Creates cron jobs for each client backup job.
* Installs wrapper scripts on the client machine to improve security.
* Creates directory for storing backups on the server.
* (*Optional*) Creates an ssh key pair on the server if needed.
* (*Optional*) Transfers SSH public key from server to client to enable ssh
  login.
* (*Optional*) Creates backup user and group on client machine.
* (*Optional*) Adds backup user to sudo.


### Setup Requirements

* PuppetDB needs to be installed for SSH keys to automatically transfer.
* Storeconfigs needs to be enabled for configurations defined on the client side
  to be installed on the backup server.
* Multiple puppet runs (client, then server, then client again) need to occur
  for all resources to be creates.


### Beginning with rsnapshot

On the backup server (backups.example.com) include the `rsnapshot::server` class
and tell it where to store the backups.

```puppet
class { 'rsnapshot::server':
  backup_path    => '/backups/rsnapshot'
}
```

On the machine you want to back up include the `rsnapshot::client` class and
tell it which server to back up to and what directories to back up.

```puppet
class { 'rsnapshot::client':
  server      => 'backups.example.com',
  directories => [
    '/etc',
    '/home',
    '/root'
  ]
}
```


## Usage

### Configuring the Server

Settings in the server class are passed to all backup configurations that end up
on that server.

This class can be included without any parameters and the defaults should work.

```puppet
class { 'rsnapshot::server':  
  config_path            => '/etc/rsnapshot',
  backup_path            => '/backups/rsnapshot',
  log_path               => '/var/log/rsnapshot',
  user                   => 'root',
  no_create_root         => 0,
  verbose                => 2,
  log_level              => 3,
  link_dest              => 1,
  sync_first             => 0,
  use_lazy_deletes       => 0,
  rsync_numtries         => 1,
  stop_on_stale_lockfile => 0,
  du_args                => '-csh'
}
```


### Configuring the Client

Settings in the client class are specific to that one client node. The
parameters in this class will get exported to a backup server and merged with
it's parameters to build the client specific configuration.

This class has two required parameters- the backup `server`, which should be an
fqdn, and an array of `directories` to back up. Additional options, such as
retain rules or cronjob times, can be overridden as needed.

```puppet
class { 'rsnapshot::client':
  server             => 'backups.example.com',
  directories        => [
    '/etc',
    '/home',
    '/root'
  ],
  user                => 'backshots',
  remote_user         => 'root',
  backup_hourly_cron  => '*/2',
  backup_time_minute  => fqdn_rand(59, 'rsnapshot_minute'),
  backup_time_hour    => fqdn_rand(23, 'rsnapshot_hour'),
  backup_time_weekday => 6,
  backup_time_dom     => 15,
  cmd_preexec         => undef,
  cmd_postexec        => undef,
  cmd_client_rsync    => '/usr/bin/rsync',
  cmd_client_sudo     => '/usr/bin/sudo',
  retain_hourly       => 6,
  retain_daily        => 7,
  retain_weekly       => 4,
  retain_monthly      => 3,
  one_fs              => undef,
  rsync_short_args    => '-a',
  rsync_long_args     => '--delete --numeric-ids --relative --delete-excluded'
  ssh_args            => undef,
  use_sudo            => true,
  push_ssh_key        => true,
  wrapper_path        => '/opt/rsnapshot_wrappers/',  
}
```


### Adding Backup Points to Profiles

This module provides a resource type, `rnapshot::backup`, that can be used to
define directories to backup outside of the `rsnapshot::client` class. This lets
developers define backup points as resources inside other classes.

For example, in a mysql profile it would make sense to backup the directory
where the mysqldumps get stored. Instead of defining that using
`rsnapshot::client` it can be added directly in the mysql profile.

```puppet

class profiles::mysql {

  class { '::mysql::server': }->

  file { '/opt/mysqldumps':
    ensure => 'directory'
  }->

  cron { 'vicarious_profiles_mysqldump':
    command => '/usr/bin/mysqldump --defaults-extra-file=/root/.my.cnf --opt --single-transaction --events --routines --triggers --hex-blob --comments --all-databases | /bin/gzip > /opt/mysqldumps/backups_\$(date +\%Y-\%m-\%d_\%H:\%M:\%S).sql.gz',
    user    => root,
    hour    => 4,
    minute  => 0
  }->

  rsnapshot::backup { "${::fqdn}_mysql_backups":
    source_path => '/opt/mysqldumps'
  }

}
```

Please note that when doing this the `rsnapshot::backup` point will only be
backup up if there is an `rsnapshot::client` definition for the machine. Without
that it is simply discarded.


### Backing Up Machines Outside of Puppet

It's also possible to add machines to the backup server that are not controlled
by Puppet. Client side features, such as account creation and ssh key transfer,
will not be available.

On the backup server define a new resource of the `rsnapshot::server::config`
type. This object takes a combination of the rsnapshot::server and
rsnapshot::client settings, and it will generate all of the configuration and
the cronjobs needed to run backups.

```puppet
rsnapshot::server::config { 'backupclient.example.com':
  server                 => $::fqdn,
  config_path            => '/etc/rsnapshot',
  backup_path            => '/backups/rsnapshot',
  log_path               => '/var/log/rsnapshot',
  backup_user            => 'root',
  backup_hourly_cron     => '*/2',
  backup_time_minute     => fqdn_rand(59, 'rsnapshot_minute'),
  backup_time_hour       => fqdn_rand(23, 'rsnapshot_hour'),
  backup_time_weekday    => 6,
  backup_time_dom        => 15,
  directories            => [
    '/etc',
    '/home',
    '/root'
  ],
  lock_path              => '/var/run',
  remote_user            => 'backshots',
  user                   => 'root',
  no_create_root         => 0,
  verbose                => 2,
  log_level              => 3,
  link_dest              => 1,
  sync_first             => 0,
  use_lazy_deletes       => 0,
  rsync_numtries         => 1,
  stop_on_stale_lockfile => 0,
  cmd_preexec            => undef,
  cmd_postexec           => undef,
  retain_hourly          => 6,
  retain_daily           => 7,
  retain_weekly          => 4,
  retain_monthly         => 3,
  one_fs                 => undef,
  rsync_short_args       => '-a',
  rsync_long_args        => '--delete --numeric-ids --relative --delete-excluded'
  du_args                => '-csh',
  use_sudo               => false,
}  
```


## Reference

### Public Classes

* [`rsnapshot::client`](#class-rsnapshotclient)
* [`rsnapshot::server`](#class-rsnapshotserver)

### Defines

* [`rsnapshot::backup`](#define-rsnapshotbackup)
* [`rsnapshot::server::config`](#define-rsnapshotserverconfig)

### Private Classes

* `rsnapshot::client::install`: Installs needed packages on client side.
* `rsnapshot::client::user`: Sets up client side user and permissions.
* `rsnapshot::client::wrappers`: Adds wrapper scripts to client machine.
* `rsnapshot::server::install`: Installs needed packages on server side.
* `rsnapshot::params` Contains default parameters used by this module.

### Private Defines

* `rsnapshot::server::backup_config`: Gets thrown and collected by the backup
   and config types.


## Resources

### Define: `rsnapshot::backup`

These resources are used to define backup points outside of the client of config
files. They create virtual resources that get collected by the config class and
included in the rsnapshot configuration.

##### Parameters

* `source_path`: The path to backup.
* `host`: The host being backed up. Defaults to $::fqdn.
* `options`: Options to be passed to rsnapshot.


### Class: `rsnapshot::client`

This class turns a machine into an rsnapshot client by adding and configuration
the user, enabling certain wrapper scripts, and exporting a configuration
resource to the backup server.

##### Parameters

* `server`: The server to backup to.
* `directories`: The directories that should be backed up.
* `includes`: An array of rsync "include" arguements.
* `excludes`: An array of rsync "exclude" arguements.
* `includes_files`: An array of rsync "include-files" arguements.
* `excludes_files`: An array of rsync "exclude-files" arguements.
* `user`: The client side user that handles backing up.
* `remote_user`: The server side user that runs backups.
* `backup_time_cron`: The cron descriptor (\*/2) to drive the hourly backup
  script.
* `backup_time_minute`: The minute that backups (of all intervals) should start.
  This defaults to fqdn_rand, giving each host a unique start time.
* `backup_time_hour`: The hour that daily backups should occur. This defaults to
  fqdn_rand, giving each host a unique start time.
* `backup_time_weekday`: The day that weekly backups should occur. This defaults
  to fqdn_rand, giving each host a random weekday for backups.
* `backup_time_dom`: The day of the month that monthly backups should occur.
  This defaults to fqdn_rand, giving each host a random day of the month.
* `cmd_preexec`: The path to any script that should run before backups.
* `cmd_postexec`: The path to any script that should run after backups.
* `cmd_client_rsync`: The path to the client side rsync binary.
* `cmd_client_sudo`: The path to the client side sudo binary.
* `retain_hourly`: The number of hourly backups to retain.
* `retain_daily`: The number of daily backups to retain.
* `retain_weekly`: The number of weekly backups to retain.
* `retain_monthly`: The number of monthly backups to retain.
* `one_fs`: Whether rsync should cross filesystem boundaries or not.
* `rsync_short_args`: A list of short arguments to pass to rsync.
* `rsync_long_args`: A list of long arguments to pass to rsync.
* `ssh_args`: A list of arguments to pass to ssh.
* `use_sudo`: If enabled sudo will be used instead of direct root access for
  rsync.
* `push_ssh_key`: If enabled the server's ssh key will be passed to this client.
* `wrapper_path`: The path to store the various wrapper script in.


### Class: `rsnapshot::server`

This class turns a machine into an rsnapshot server by instaling the rsnapshot
packages and collecting the exported configurations from the client machines.

##### Parameters

* `config_path`: Directory to place the configuration files in.
* `backup_path`: Directory to store all the backups in.
* `log_path`: Directory to place the configuration files in.
* `lock_path`: Directory to place the lock files in.
* `user`: The server side user running the backup scripts.
* `no_create_root`: Whether or not to create the rsnapshot backup directories.
* `verbose`: A level, one through five, describing the level of information
  outputted.
* `log_level`: A level, one through five, describing the level of information
  logged.
* `link_dest`: Whether rsync supports the --link-dest flag or not.
* `sync_first`: This requires syncing to occur with a seperate call to
  rsnapshot. This is not recommended.
* `use_lazy_deletes`: When enabled rsnapshot will move the oldest directory to
  [interval].delete and remove it after syncing new backups
* `rsync_numtries`: How many times to retry rsync after a failure.
* `stop_on_stale_lockfile`: Enabling this stop rsnapshot if PID in lockfile is
  not running
* `du_args`: Arguments for the du program. GNU is preferred.


### Define: `rsnapshot::server::config`

This class creates the client specific configuration and cron jobs on the
rsnapshot server. It is typically created from the `rsnapshot::client` class and
exported to the `rsnapshot::server` class but it can also be created directly on
an rsnapshot server to backup clients that are not controlled by puppet.

##### Parameters

* `config_path`: Directory to place the configuration files in.
* `backup_path`: Directory to store all the backups in.
* `log_path`: Directory to place the configuration files in.
* `lock_path`: Directory to place the lock files in.
* `backup_user`: The server side user running the backup scripts.
* `remote_user`: The client side user the server uses to log in.
* `directories`: The directories that should be backed up.
* `lock_path`: Directory to place the lock files in.
* `includes`: An array of rsync "include" arguements.
* `excludes`: An array of rsync "exclude" arguements.
* `includes_files`: An array of rsync "include-files" arguements.
* `excludes_files`: An array of rsync "exclude-files" arguements.
* `no_create_root`: Whether or not to create the rsnapshot backup directories.
* `verbose`: A level, one through five, describing the level of information
  outputted.
* `log_level`: A level, one through five, describing the level of information
  logged.
* `link_dest`: Whether rsync supports the --link-dest flag or not.
* `sync_first`: This requires syncing to occur with a seperate call to
  rsnapshot. This is not recommended.
* `use_lazy_deletes`: When enabled rsnapshot will move the oldest directory to
  [interval].delete and remove it after syncing new backups
* `rsync_numtries`: How many times to retry rsync after a failure.
* `stop_on_stale_lockfile`: Enabling this stop rsnapshot if PID in lockfile is
  not running
* `server`: The server to backup to. Defaults to the current $::fqdn.
* `backup_time_cron`: The cron descriptor (\*/2) to drive the hourly backup
  script.
* `backup_time_minute`: The minute that backups (of all intervals) should start.
  This defaults to fqdn_rand, giving each host a unique start time.
* `backup_time_hour`: The hour that daily backups should occur. This defaults to
  fqdn_rand, giving each host a unique start time.
* `backup_time_weekday`: The day that weekly backups should occur. This defaults
  to fqdn_rand, giving each host a random weekday for backups.
* `backup_time_dom`: The day of the month that monthly backups should occur.
  This defaults to fqdn_rand, giving each host a random day of the month.
* `cmd_preexec`: The path to any script that should run before backups.
* `cmd_postexec`: The path to any script that should run after backups.
* `retain_hourly`: The number of hourly backups to retain.
* `retain_daily`: The number of daily backups to retain.
* `retain_weekly`: The number of weekly backups to retain.
* `retain_monthly`: The number of monthly backups to retain.
* `one_fs`: Whether rsync should cross filesystem boundaries or not.
* `rsync_short_args`: A list of short arguments to pass to rsync.
* `rsync_long_args`: A list of long arguments to pass to rsync.
* `ssh_args`: A list of arguments to pass to ssh.
* `du_args`: Arguments for the du program. GNU is preferred.
* `use_sudo`: If enabled sudo will be used instead of direct root access for
  rsync.
* `wrapper_path`: The path to store the various wrapper script in.
* `wrapper_sudo`: The name of the sudo wrapper script.
* `wrapper_rsync_sender`: The name of the rsync sender wrapper script.
* `wrapper_rsync_ssh`: The name of the rsync ssh wrapper script.


## Development

Contributions are always welcome. Please read the [Contributing Guide](CONTRIBUTING.md)
to get started.