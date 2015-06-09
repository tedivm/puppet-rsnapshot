define rsnapshot::server::config (
  $config_path = undef,
  $log_path = undef,
  $backup_path = undef,
  $backup_user = undef,
  $backup_time_minute = undef,
  $backup_time_hour = undef,
  $backup_time_weekday = undef,
  $backup_time_dom = undef,
  $directories = {},
  $config_path = undef,
  $log_path = undef,
  $lock_path = unfef,
  $backup_dir = undef,
  $remote_user = undef,
  $no_create_root = undef,
  $verbose = undef,
  $loglevel = undef,
  $link_dest = undef,
  $sync_first = undef,
  $use_lazy_deletes = undef,
  $rsync_numtries = undef,
  $stop_on_stale_lockfile = undef,
  $user = undef,
  $directories = undef,
  $server = undef,
  $backup_hourly_cron = undef,
  $backup_time_minute = undef,
  $backup_time_hour = undef,
  $backup_time_weekday = undef,
  $backup_time_dom = undef,
  $cmd_preexec = undef,
  $cmd_postexec = undef,
  $retain_hourly = undef,
  $retain_daily = undef,
  $retain_weekly = undef,
  $retain_monthly = undef,
  $one_fs = undef,
  $rsync_short_args = undef,
  $rsync_long_args = undef,
  $ssh_args = undef,
  $du_args = undef,
  $use_sudo = undef
  ) {

  $log_file = "${log_path}/${name}-rsnapshot.log"
  $lock_file = "$lock_path}/${name}-rsnapshot.pid"
  $config_file = "${config_path}/${name}-rsnapshot.conf"


  if($use_sudo) {
    $rsync_long_args_final = "$rsync_long_args --rsync-path=\"sudo rsync\""
  } else {
    $rsync_long_args_final = $rsync_long_args
  }

  file { $log_file :
    ensure  => present,
    require => File[$log_path]
  } ->

  # cronjobs

  ## hourly
  cron { "rsnapshot-${name}-hourly" :
    command => '/usr/local/bin/rsnapshot hourly',
    user    => 'root',
    hour    => $backup_hourly_cron,
    minute  => $backup_time_minute
  } ->

  ## daily
  cron { "rsnapshot-${name}-daily" :
    command => '/usr/local/bin/rsnapshot daily',
    user    => 'root',
    hour    => $backup_time_hour,
    minute  => $backup_time_minute
  } ->

  ## weekly
  cron { "rsnapshot-${name}-weekly" :
    command => '/usr/local/bin/rsnapshot weekly',
    user    => 'root',
    hour    => ($backup_time_hour + 3) % 24,
    minute  => $backup_time_minute,
    weekday => $backup_time_weekday
  } ->

  ## monthly
  cron { "rsnapshot-${name}-monthly" :
    command  => '/usr/local/bin/rsnapshot monthly',
    user     => 'root',
    hour     => ($backup_time_hour + 6) % 24,
    minute   => $backup_time_minute,
    monthday => $backup_time_dom
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
    ssh_args => $ssh_args,
  }

  $lockfile = "${rsnapshot::server::lock_path}${name}"
  $logfile = "${rsnapshot::server::log_path}${name}"

  # config file
  concat { $config_file :
    owner => $::rsnapshot::server::user,
    group => $::rsnapshot::server::user,
    mode  => '0644',
    warn  => true
  }

  concat::fragment { "${config_file}_header" :
    target  => $config_file,
    content => template('rsnapshot/config.erb'),
    order   => 01
  }

  Rsnapshot::Server::Backup_config <<| host == $name |>> {
    config_file => $config_file,
    backup_user => $backup_user
  }

}
