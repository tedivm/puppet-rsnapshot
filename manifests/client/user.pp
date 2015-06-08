class rsnapshot::client::user (
  $local_user = '',
  $remote_user = '',
  $server = '',
  $use_sudo = true,
  $push_ssh_key = true
  ) {

  # Setup User
  user { $local_user :
    ensure => present
  }

  ## Get Key for remote backup user
  if $push_ssh_key {
    sshkeys::set_authorized_key { "${remote_user} to ${local_user}":
      local_user  => $local_user,
      remote_user => "${remote_user}@${server}",
      require     => User[$local_user]
    }
  }

  # Add sudo config if needed.
  if $use_sudo {
    sudo::conf { 'backup user':
      priority => 99,
      content  => "${local_user} ALL= NOPASSWD: /usr/bin/rsync",
      require  => User[$local_user]
    }
  }
}
