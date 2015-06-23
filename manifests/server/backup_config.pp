define rsnapshot::server::backup_config (
  $config_file,
  $source_path,
  $host,
  $server,
  $client_user = $rsnapshot::params::client_backup_user,
  $options = {},
  ) {
  assert_private()
  concat::fragment { "${config_file}_entry_${source_path}" :
    target  => $config_file,
    content => template('rsnapshot/backup_point.erb'),
    order   => 20
  }

}
