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
  $log_path = $rsnapshot::params::server_log_path,
  $user = $rsnapshot::params::server_user
  ) {

  include rsnapshot::server::install

  # Add logging folder
  file { $log_path :
    'ensure' => directory,
    'owner'  => $user,
    'group'  => $user

  }

  # Add config path
  file { $config_path :
    'ensure' => directory,
    'owner'  => $user,
    'group'  => $user
  }

  rsnapshot::client::config <<| server == $::fqdn |>> {
    $config_path = $rsnapshot::server::config_path,
    $log_path = $rsnapshot::server::log_path,
  }

}
