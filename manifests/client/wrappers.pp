class rsnapshot::client::wrappers (
  $wrapper_path = $rsnapshot::params::wrapper_path,
  $cmd_client_rsync = $rsnapshot::params::cmd_client_rsync,
  $cmd_client_sudo = $rsnapshot::params::cmd_client_sudo,
) inherits rsnapshot::params {

  assert_private()

  $wrapper_rsync_sender = $rsnapshot::params::wrapper_rsync_sender
  $wrapper_sudo = $rsnapshot::params::wrapper_sudo

  file { $wrapper_path :
    ensure  => directory,
    owner  => 'root',
    group => 'root',
    mode  => '0744',
  }->

  file { "$wrapper_path/${wrapper_rsync_sender}" :
    ensure  => present,
    content => template("rsnapshot/${wrapper_rsync_sender}.erb"),
    owner => 'root',
    group => 'root',
    mode  => '0755',
  }->

  file { "$wrapper_path/${wrapper_rsync_ssh}" :
    ensure  => present,
    content => template("rsnapshot/${wrapper_rsync_ssh}.erb"),
    owner => 'root',
    group => 'root',
    mode  => '0755',
  }->

  file { "${wrapper_path}/${wrapper_sudo}" :
    ensure  => present,
    content => template("rsnapshot/${wrapper_sudo}.erb"),
    owner => 'root',
    group => 'root',
    mode  => '0755',
  }

}
