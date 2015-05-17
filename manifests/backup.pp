define rsnapshot::backup (
  $source_dir,
  $host = $::fqdn,
  $options = {},
  ) {

  @@rsnapshot::server::backup_config { "${host}_${source_dir}":
    source_dir => $source_dir,
    host       => $host,
    server     => $rsnapshot::client::server,
    user       => $::rsnapshot::client::user,
    options    => $options
  }

}
