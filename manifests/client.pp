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
  $directories = {},
  $server = undef,
  $user = $rsnapshot::params::client_user,
  $remote_user = $rsnapshot::params::server_user,
  $directories = {}
  ) {

  # Install
  include rsnapshot::client::install

  # Add User
  class { "rsnapshot::client::user" :
    remote_user => "${remote_user}@${server}",
    local_user => $user
  }

  # Export client object to get picked up by the server.
  @@rsnapshot::client::config { $::fqdn:
    $user = $rsnapshot::client::user,
    $directories = $rsnapshot::client::directories
  }

}
