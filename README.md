# rsnapshot

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with rsnapshot](#setup)
    * [What rsnapshot affects](#what-rsnapshot-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with rsnapshot](#beginning-with-rsnapshot)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

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

The very basic steps needed for a user to get the module up and running.

If your most recent release breaks compatibility or requires particular steps
for upgrading, you may wish to include an additional section here: Upgrading
(For an example, see http://forge.puppetlabs.com/puppetlabs/firewall).

## Usage

Put the classes, types, and resources for customizing, configuring, and doing
the fancy stuff with your module here.

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


### Define: `rsnapshot::backup`

These resources are used to define backup points outside of the client of config
files. They create virtual resources that get collected by the config class and
included in the rsnapshot configuration.

##### Parameters

* `parameter`: Description


### Class: `rsnapshot::client`

This class turns a machine into an rsnapshot client by adding and configuration
the user, enabling certain wrapper scripts, and exporting a configuration
resource to the backup server.

##### Parameters

* `parameter`: Description


### Class: `rsnapshot::server`

This class turns a machine into an rsnapshot server by instaling the rsnapshot
packages and collecting the exported configurations from the client machines.

##### Parameters

* `parameter`: Description


### Define: `rsnapshot::server::config`

This class creates the client specific configuration and cron jobs on the
rsnapshot server. It is typically created from the `rsnapshot::client` class and
exported to the `rsnapshot::server` class but it can also be created directly on
an rsnapshot server to backup clients that are not controlled by puppet.

##### Parameters

* `parameter`: Description


## Limitations

This is where you list OS compatibility, version compatibility, etc.

## Development

Since your module is awesome, other users will want to play with it. Let them
know what the ground rules for contributing are.
