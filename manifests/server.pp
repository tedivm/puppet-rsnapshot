# == Class: rsnapshot
#
# Full description of class rsnapshot here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  class { 'rsnapshot':
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2015 Your name here, unless otherwise noted.
#
class rsnapshot::server(
  $config_path = $rsnapshot::params::server_config_path,
  $backup_path = $rsnapshot::params::server_backup_path,
  $log_path = $rsnapshot::params::server_log_path,
  $lock_path = $rsnapshot::params::lock_path,
  $server_user = $rsnapshot::params::server_user,
  $no_create_root = $rsnapshot::params::no_create_root,
  $verbose = $rsnapshot::params::verbose,
  $log_level = $rsnapshot::params::log_level,
  $link_dest = $rsnapshot::params::link_dest,
  $sync_first = $rsnapshot::params::sync_first,
  $use_lazy_deletes = $rsnapshot::params::use_lazy_deletes,
  $rsync_numtries = $rsnapshot::params::rsync_numtries,
  $stop_on_stale_lockfile = $rsnapshot::params::stop_on_stale_lockfile,
  $du_args = $rsnapshot::params::du_args,
  $systemd = $rsnapshot::params::systemd,
  $systemd_dir = $rsnapshot::params::systemd_dir,
  ) inherits rsnapshot::params {

  include rsnapshot::server::install

  # Add logging folder
  file { $log_path :
    ensure => directory,
    owner  => $server_user,
    group  => $server_user
  }

  # Add config path
  file { $config_path :
    ensure => directory,
    owner  => $server_user,
    group  => $server_user
  }->

  # Add logging folder
  file { $backup_path :
    ensure => directory,
    owner  => $server_user,
    group  => $server_user
  }->

  Rsnapshot::Server::Config <<| server == $::fqdn |>> {
    config_path            => $::rsnapshot::server::config_path,
    log_path               => $::rsnapshot::server::log_path,
    lock_path              => $::rsnapshot::server::lock_path,
    backup_path            => $::rsnapshot::server::backup_path,
    server_user            => $server_user,
    no_create_root         => $::rsnapshot::server::no_create_root,
    verbose                => $::rsnapshot::server::verbose,
    loglevel               => $::rsnapshot::server::loglevel,
    link_dest              => $::rsnapshot::server::link_dest,
    sync_first             => $::rsnapshot::server::sync_first,
    use_lazy_deletes       => $::rsnapshot::server::use_lazy_deletes,
    rsync_numtries         => $::rsnapshot::server::rsync_numtries,
    stop_on_stale_lockfile => $::rsnapshot::server::stop_on_stale_lockfile,
    du_args                => $::rsnapshot::server::du_args,
    systemd                => $systemd,
    systemd_dir            => $systemd_dir,
  }

  # systemd services
  if $systemd {
    ['hourly', 'daily', 'weekly', 'monthly'].each |String $interval| {
      $config_path_norm = regsubst($config_path, '\/$', '')

      file { "${systemd_dir}/rsnapshot-${interval}@.service":
        ensure => file,
        content => epp('rsnapshot/systemd_service.epp',
          {
            description => "Create an rsnapshot backup for %i (${interval})",
            command     => "${rsnapshot::server::cmd_rsnapshot} -c \"${config_path_norm}/%i-rsnapshot.conf\" ${interval}",
          })
      }
    }
  }
}
