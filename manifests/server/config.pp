define rsnapshot::server::config (
  $fqdn = $name,
  $config_path = $rsnapshot::params::server_config_path,
  $backup_path = $rsnapshot::params::server_backup_path,
  $log_path = $rsnapshot::params::server_log_path,
  $lock_path = $rsnapshot::params::lock_path,
  $server_user = $rsnapshot::params::server_user,
  $client_user = $rsnapshot::params::client_user,
  $directories = {},
  $includes = {},
  $excludes = {},
  $include_files = {},
  $exclude_files = {},
  $server = $::fqdn,
  $no_create_root = $rsnapshot::params::no_create_root,
  $verbose = $rsnapshot::params::verbose,
  $log_level = $rsnapshot::params::log_level,
  $link_dest = $rsnapshot::params::link_dest,
  $sync_first = $rsnapshot::params::sync_first,
  $use_lazy_deletes = $rsnapshot::params::use_lazy_deletes,
  $rsync_numtries = $rsnapshot::params::rsync_numtries,
  $stop_on_stale_lockfile = $rsnapshot::params::stop_on_stale_lockfile,
  $backup_hourly_cron = $rsnapshot::params::backup_hourly_cron,
  $backup_time_minute = $rsnapshot::params::backup_time_minute,
  $backup_time_hour = $rsnapshot::params::backup_time_hour,
  $backup_time_weekday = $rsnapshot::params::backup_time_weekday,
  $backup_time_dom = $rsnapshot::params::backup_time_dom,
  $cmd_preexec = $rsnapshot::params::cmd_preexec,
  $cmd_postexec = $rsnapshot::params::cmd_postexec,
  $retain_hourly = $rsnapshot::params::retain_hourly,
  $retain_daily = $rsnapshot::params::retain_daily,
  $retain_weekly = $rsnapshot::params::retain_weekly,
  $retain_monthly = $rsnapshot::params::retain_monthly,
  $one_fs = $rsnapshot::params::one_fs,
  $rsync_short_args = $rsnapshot::params::rsync_short_args,
  $rsync_long_args = $rsnapshot::params::rsync_long_args,
  $ssh_args = $rsnapshot::params::ssh_args,
  $wrapper_path = $rsnapshot::params::wrapper_path,
  $du_args = $rsnapshot::params::du_args,
  $use_sudo = false,
  $wrapper_sudo = $rsnapshot::params::wrapper_sudo,
  $wrapper_rsync_sender = $rsnapshot::params::wrapper_rsync_sender,
  $wrapper_rsync_ssh = $rsnapshot::params::wrapper_rsync_ssh,
  $systemd = $rsnapshot::params::systemd,
  $systemd_dir = $rsnapshot::params::systemd_dir,
  ) {

  # Remove trailing slashes.
  $log_path_norm = regsubst($log_path, '\/$', '')
  $lock_path_norm = regsubst($lock_path, '\/$', '')
  $config_path_norm = regsubst($config_path, '\/$', '')
  $backup_path_norm = regsubst($backup_path, '\/$', '')
  $wrapper_path_norm = regsubst($wrapper_path, '\/$', '')

  $log_file = "${log_path_norm}/${name}-rsnapshot.log"
  $lock_file = "${lock_path_norm}/${name}-rsnapshot.pid"
  $config_file = "${config_path_norm}/${name}-rsnapshot.conf"
  $snapshot_root = "${backup_path_norm}/${name}"

  if($ssh_args) {
    $ssh_args_processed = "-e 'ssh ${ssh_args}'"
  } else {
    $ssh_args_processed = ''
  }

  if($use_sudo) {
    $rsync_wrapper_processed = "--rsync-path=\"${wrapper_path_norm}/${wrapper_sudo}\""
  } else {
    $rsync_wrapper_processed = "--rsync-path=\"${wrapper_path_norm}/${wrapper_rsync_ssh}\""
  }

  $rsync_long_args_final = strip("${ssh_args_processed} ${rsync_long_args} ${rsync_wrapper_processed}")


  file { $snapshot_root :
    ensure  => directory,
    require => File[$backup_path]
  } ->

  file { $log_file :
    ensure  => present,
    require => File[$log_path]
  }

  # systemd service/timer
  if $systemd {
    ::rsnapshot::server::service{ $name:
      backup_hourly_timer => regsubst($backup_hourly_cron, '\*', '0'),
      backup_time_minute  => $backup_time_minute,
      backup_time_hour    => $backup_time_hour,
      backup_time_weekday => $backup_time_weekday,
      backup_time_dom     => $backup_time_dom,
      retain_hourly       => $retain_hourly,
      retain_daily        => $retain_daily,
      retain_weekly       => $retain_weekly,
      retain_monthly      => $retain_monthly,
      systemd_dir         => $systemd_dir,
    }

  # cronjobs
  } else {
    ## hourly
    if ($retain_hourly > 0) {
      cron { "rsnapshot-${name}-hourly":
        command => "${rsnapshot::server::cmd_rsnapshot} -c ${config_file} hourly",
        user    => $server_user,
        hour    => $backup_hourly_cron,
        minute  => $backup_time_minute
      }
    }

    ## daily
    if ($retain_daily > 0) {
      cron { "rsnapshot-${name}-daily":
        command => "${rsnapshot::server::cmd_rsnapshot} -c ${config_file} daily",
        user    => $server_user,
        hour    => $backup_time_hour,
        minute  => ($backup_time_minute + 50) % 60
      }
    }

    ## weekly
    if ($retain_weekly > 0) {
      cron { "rsnapshot-${name}-weekly":
        command => "${rsnapshot::server::cmd_rsnapshot} -c ${config_file} weekly",
        user    => $server_user,
        hour    => ($backup_time_hour + 3) % 24,
        minute  => ($backup_time_minute + 50) % 60,
        weekday => $backup_time_weekday
      }
    }

    ## monthly
    if ($retain_monthly > 0) {
      cron { "rsnapshot-${name}-monthly":
        command  => "${rsnapshot::server::cmd_rsnapshot} -c ${config_file} monthly",
        user     => $server_user,
        hour     => ($backup_time_hour + 7) % 24,
        minute   => ($backup_time_minute + 50) % 60,
        monthday => $backup_time_dom
      }
    }
  }

  $programs = {
    cmd_cp => $rsnapshot::server::cmd_cp,
    cmd_rm => $rsnapshot::server::cmd_rm,
    cmd_rsync => $rsnapshot::server::cmd_rsync,
    cmd_ssh => $rsnapshot::server::cmd_ssh,
    cmd_logger => $rsnapshot::server::cmd_logger,
    cmd_du => $rsnapshot::server::cmd_du,
    cmd_rsnapshot_diff => $rsnapshot::server::cmd_rsnapshot_diff,
    linux_lvm_cmd_lvcreate => $rsnapshot::server::linux_lvm_cmd_lvcreate,
    linux_lvm_cmd_lvremove => $rsnapshot::server::linux_lvm_cmd_lvremove,
    linux_lvm_cmd_mount => $rsnapshot::server::linux_lvm_cmd_mount,
    linux_lvm_cmd_umount => $rsnapshot::server::linux_lvm_cmd_umount,
  }

  $options = {
    lockfile => $lock_file,
    logfile => $log_file,
    no_create_root => $no_create_root,
    verbose => $verbose,
    loglevel => $log_level,
    link_dest => $link_dest,
    sync_first => $sync_first,
    use_lazy_deletes => $use_lazy_deletes,
    rsync_numtries => $rsync_numtries,
    stop_on_stale_lockfile => $stop_on_stale_lockfile,
    cmd_preexec => $cmd_preexec,
    cmd_postexec => $cmd_postexec,
    one_fs => $one_fs,
    rsync_short_args => $rsync_short_args,
    rsync_long_args => $rsync_long_args_final,
    du_args => $du_args,
  }

  $lockfile = "${rsnapshot::server::lock_path}${name}"
  $logfile = "${rsnapshot::server::log_path}${name}"

  # config file
  concat { $config_file :
    owner => $server_user,
    group => $server_user,
    mode  => '0644',
    warn  => true
  }

  concat::fragment { "${config_file}_rsnapshot_header" :
    target  => $config_file,
    content => template('rsnapshot/config.erb'),
    order   => 01
  }

  Rsnapshot::Server::Backup_config <<| host == $name |>> {
    config_file => $config_file
  }

}
