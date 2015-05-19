# Class: rsnapshot::params
#
# This class manages parameters for the rsnapshot module
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class rsnapshot::params {
  $server_packages = [ 'rsnapshot' ]
  $client_packages = [ 'rsync' ]
  $client_user = 'backshots'
  $server_user = 'root'
  $server_log_path = '/var/log/rsnapshot'
  $server_config_path = '/etc/rsnapshot'
  $server_backup_path = '/backups/rsnapshot'

  $cmd_preexec = undef
  $cmd_postexec = undef
  $no_create_root = 0

  $retain_hourly = 6
  $retain_daily = 7
  $retain_weekly = 4
  $retain_monthly = 3

  $verbose = 2
  $loglevel = 3
  $logfile = '/var/log/'

  $backup_hourly_cron = '*/2'
  $backup_time_minute = fqdn_rand(59, 'rsnapshot_minute')
  $backup_time_hour = fqdn_rand(23, 'rsnapshot_hour')
  $backup_time_weekday = 6
  $backup_time_dom = 15


  case $::osfamily {
    debian: {
      $cmd_cp = '/bin/cp'
      $cmd_rm = '/bin/rm'
      $cmd_rsync = '/usr/bin/rsync'
      $cmd_ssh = '/usr/bin/ssh'
      $cmd_logger = '/usr/bin/logger'
      $cmd_du = '/usr/bin/du'
      $cmd_rsnapshot_diff = '/usr/bin/rsnapshot-diff'
      $linux_lvm_cmd_lvcreate = '/sbin/lvcreate'
      $linux_lvm_cmd_lvremove = '/sbin/lvremove'
      $linux_lvm_cmd_mount = '/bin/mount'
      $linux_lvm_cmd_umount = '/bin/umount'
      $lock_path = '/var/run/'
      $log_path = '/var/log/'
    }
    default: {
      $cmd_cp = undef
      $cmd_rm = undef
      $cmd_rsync = '/usr/bin/rsync'
      $cmd_ssh = undef
      $cmd_logger = undef
      $cmd_du = undef
      $cmd_rsnapshot_diff = undef
      $linux_lvm_cmd_lvcreate = undef
      $linux_lvm_cmd_lvremove = undef
      $linux_lvm_cmd_mount = undef
      $linux_lvm_cmd_umount = undef
      $lock_path = '/var/run/'
      $log_path = '/var/log/'
    }
  }

}
