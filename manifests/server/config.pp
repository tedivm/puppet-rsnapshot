define rsnapshot::server::config (
  $config_path = $rsnapshot::server::server_config_path,
  $log_path = $rsnapshot::params::server_log_path,
  $backup_path = $rsnapshot::params::server_backup_path,
  $backup_user = $rsnapshot::params::client_backup_user,
  $directories = {}
  ) {

  file { "${log_path}/${name}-rsnapshot.log" :
    ensure  => present,
    require => File[$log_path]
  } ->

  # cronjobs

  ## hourly
  cron { "rsnapshot-${name}-hourly" :
    command => '/usr/local/bin/rsnapshot hourly',
    user    => 'root',
    hour    => */2,
    minute  => 0
  } ->

  ## daily
  cron { "rsnapshot-${name}-daily" :
    command => '/usr/local/bin/rsnapshot daily',
    user    => 'root',
    hour    => 3,
    minute  => 0
  } ->

  ## weekly
  cron { "rsnapshot-${name}-weekly" :
    command => '/usr/local/bin/rsnapshot weekly',
    user    => 'root',
    hour    => 4,
    minute  => 0,
    weekday => 6
  } ->

  ## monthly
  cron { "rsnapshot-${name}-monthly" :
    command  => '/usr/local/bin/rsnapshot monthly',
    user     => 'root',
    hour     => 5,
    minute   => 0,
    monthday => 1
  }


  $config_file = "${config_path}/${name}-rsnapshot.conf"

  $programs = {
    cmd_cp = $rsnapshot::server::cmd_cp,
    cmd_rm = $rsnapshot::server::cmd_rm,
    cmd_rsync = $rsnapshot::server::cmd_rsync,
    cmd_ssh = $rsnapshot::server::cmd_ssh,
    cmd_logger = $rsnapshot::server::cmd_logger,
    cmd_du = $rsnapshot::server::cmd_du,
    cmd_rsnapshot_diff = $rsnapshot::server::cmd_rsnapshot_diff,
    linux_lvm_cmd_lvcreate = $rsnapshot::server::linux_lvm_cmd_lvcreate,
    linux_lvm_cmd_lvremove = $rsnapshot::server::linux_lvm_cmd_lvremove,
    linux_lvm_cmd_mount = $rsnapshot::server::linux_lvm_cmd_mount,
    linux_lvm_cmd_umount = $rsnapshot::server::linux_lvm_cmd_umount,
  }

  $options = {
    lockfile = "${rsnapshot::server::lock_path}${name}",
    logfile = "${rsnapshot::server::log_path}${name}",
    verbose = $rsnapshot::server::verbose,
  }

  $directories = {
  }


  $lockfile = "${rsnapshot::server::lock_path}${name}"
  $logfile = "${rsnapshot::server::log_path}${name}"

  # config file
  concat { $config_file :
    owner => $::rsnapshot::server::user,
    group => $::rsnapshot::server::user,
    mode  => '0644'
    warn  => true
  }

  concat::fragment { "${config_file}_header" :
    target  => $config_file,
    content => template('rsnapshot/config.erb'),
    order   => 01
  }

  rsnapshot::server::backup_config <<| host == $name |>> {
    config_file => $config_file,
    backup_user => $backup_user
  }

}