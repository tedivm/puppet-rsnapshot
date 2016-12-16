define rsnapshot::backup (
  $source_path,
  $host = $::fqdn,
  $options = {},
  ) {

  @@rsnapshot::server::backup_config { "${host}_${source_path}":
    source_path => $source_path,
    host        => $host,
    server      => $::rsnapshot::client::server,
    client_user => $::rsnapshot::client::client_user,
    options     => $options,
    config_file => undef,
  }

}
