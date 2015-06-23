class rsnapshot::client::user (
  $client_user = '',
  $server_user = '',
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
  group { $client_user :
    ensure         => present,
  } ->

  # Setup User
  user { $client_user :
    ensure         => present,
    home           => "/home/${client_user}",
    managehome     => true,
    purge_ssh_keys => true,
    shell          => '/bin/bash',
    gid            => $client_user,
    password       => '*'
  }

  ## Get Key for remote backup user
  if $push_ssh_key {
    $server_user_exploded = "${server_user}@${server}"
    $backup_server_ip = inline_template("<% _erbout.concat(Resolv::DNS.open.getaddress('${server}').to_s) %>")
    sshkeys::set_authorized_key { "${server_user_exploded} to ${client_user}":
      local_user  => $client_user,
      remote_user => $server_user_exploded,
      require     => User[$client_user],
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
      content  => "${client_user} ALL= NOPASSWD: ${wrapper_path}/rsync_sender.sh",
      require  => User[$client_user]
    }
  }
}
