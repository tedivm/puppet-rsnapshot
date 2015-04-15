define rsnapshot::client::backup_point (
  $config_file,
  $host = $::fqdn,
  $user = $rsnapshot::params::client_backup_user,
  $source_dir,
  $backup_dir = $rsnapshot::params::server_backup_path,
  $options = {},
  ) {

  $backup_dir_final = "${backup_dir}/${host}"
  file_line { 'dir':
    path => $config_file,
    content => template('rsnapshot/backup_point.erb')
  }
}
