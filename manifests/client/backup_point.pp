define rsnapshot::client::backup_point (
  $config_file,
  $source_dir = '',
  $host = $::fqdn,
  $user = $rsnapshot::params::client_backup_user,
  $backup_dir = $rsnapshot::params::server_backup_path,
  $options = {},
  ) {

  $backup_dir_final = "${backup_dir}/${host}"

  concat::fragment { "${config_file}_entry_${source_dir}" :
    target  => $config_file,
    content => template('rsnapshot/backup_point.erb'),
    order   => 20
  }

}
