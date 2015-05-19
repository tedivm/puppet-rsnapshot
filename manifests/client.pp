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
class rsnapshot::client (
  $server,
  $directories = {},
  $user = $rsnapshot::params::client_user,
  $remote_user = $rsnapshot::params::server_user,
  $backup_hourly_cron = $rsnapshot::params::backup_hourly_cron,
  $backup_time_minute = $rsnapshot::params::backup_time_minute,
  $backup_time_hour = $rsnapshot::params::backup_time_hour,
  $backup_time_weekday = $rsnapshot::params::backup_time_weekday,
  $backup_time_dom = $rsnapshot::params::backup_time_dom
  ) inherits rsnapshot::params {

  # Install
  include rsnapshot::client::install

  # Add User
  class { 'rsnapshot::client::user' :
    remote_user => "${remote_user}@${server}",
    local_user  => $user,
    server      => $server
  }

  # Export client object to get picked up by the server.
  @@rsnapshot::server::config { $::fqdn:
    'user'                => $rsnapshot::client::user,
    'directories'         => $rsnapshot::client::directories,
    'server'              => $server,
    'backup_hourly_cron'  => $backup_hourly_cron,
    'backup_time_minute'  => $backup_time_minute,
    'backup_time_hour'    => $backup_time_hour,
    'backup_time_weekday' => $backup_time_weekday,
    'backup_time_dom'     => $backup_time_dom
  }

}
