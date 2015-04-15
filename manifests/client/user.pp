class rsnapshot::client::user (
  $local_user = "",
  $remote_user = "",
  ) {

  # Setup User
  user { $local_user :
    ensure => present
  }

  sudo::conf { 'backup user':
    priority => 10,
    content  => "$local_user ALL= NOPASSWD: /usr/bin/rsync",
    require => User[$local_user]
  }

  ## Get Key for remote backup user
  sshkeys::set_authorized_key { "${remote_user} to ${local_user}":
    local_user  => $local_user,
    remote_user => "${remote_user}@${server}",
    require => User[$local_user]
  }
}
