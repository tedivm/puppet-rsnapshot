class rsnapshot::client::user (
  $local_user = '',
  $remote_user = '',
  $server = '',
  $use_sudo = true,
  $push_ssh_key = true
  ) {


  # Setup Group
  group { $local_user :
    ensure         => present,
  } ->

  # Setup User
  user { $local_user :
    ensure         => present,
    home           => "/home/${local_user}",
    managehome     => true,
    purge_ssh_keys => true,
    shell          => '/bin/bash',
    gid            => $local_user
  }

  ## Get Key for remote backup user
  if $push_ssh_key {
    sshkeys::set_authorized_key { "${remote_user} to ${local_user}":
      local_user  => $local_user,
      remote_user => $remote_user,
      require     => User[$local_user]
    }
  }

  # Add sudo config if needed.
  if $use_sudo {
    sudo::conf { 'backup_user':
      priority => 99,
      content  => "${local_user} ALL= NOPASSWD: /usr/bin/rsync",
      require  => User[$local_user]
    }
  }
}
