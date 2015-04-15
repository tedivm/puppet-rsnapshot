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
}
