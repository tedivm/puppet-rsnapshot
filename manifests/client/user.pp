class rsnapshot::client::user (
  $local_user = '',
  $remote_user = '',
  $server = '',
  $use_sudo = true,
  $push_ssh_key = true,
  $wrapper_path = '',
  $wrapper_sudo = $rsnapshot::params::wrapper_sudo,
  $wrapper_rsync_sender = $rsnapshot::params::wrapper_rsync_sender,
  $wrapper_rsync_ssh = $rsnapshot::params::wrapper_rsync_ssh,
  ) {

  assert_private()

  $wrapper_path_norm = regsubst($wrapper_path, '\/$', '')
  if($use_sudo) {
    $allowed_command = "${wrapper_path_norm}/${wrapper_sudo}"
  } else {
    $allowed_command = "${wrapper_path_norm}/${wrapper_rsync_ssh}"
  }


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
    gid            => $local_user,
    password       => '*'
  }

  ## Get Key for remote backup user
  if $push_ssh_key {
    $backup_server_ip = inline_template("<% _erbout.concat(Resolv::DNS.open.getaddress('$server').to_s) %>")
    sshkeys::set_authorized_key { "${remote_user} to ${local_user}":
      local_user  => $local_user,
      remote_user => $remote_user,
      require     => User[$local_user],
      options     => [
        "command=\"${allowed_command}\"",
        'no-port-forwarding',
        'no-agent-forwarding',
        'no-X11-forwarding',
        'no-pty',
        "from=\"${backup_server_ip},${server}\""
      ]
    }
  }

  # Add sudo config if needed.
  if $use_sudo {
    sudo::conf { 'backup_user':
      priority => 99,
      content  => "${local_user} ALL= NOPASSWD: ${wrapper_path}/rsync_sender.sh",
      require  => User[$local_user]
    }
  }
}
