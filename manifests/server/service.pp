define rsnapshot::server::service (
  $backup_hourly_timer,
  $backup_time_minute,
  $backup_time_hour,
  $backup_time_weekday,
  $backup_time_dom,
  $retain_hourly,
  $retain_daily,
  $retain_weekly,
  $retain_monthly,
  $systemd_dir = '/etc/systemd/system',
) {
  # Get the minute/hour offsets for the various timers.
  # These are identical to the cronjob.
  $minute = ($backup_time_minute + 50) % 60;
  $hour_weekly = ($backup_time_hour + 3) % 24;
  $hour_monthly = ($backup_time_hour + 7) % 24;

  # Map the weekday to three-letter English.
  $day = $backup_time_weekday ? {
    0       => 'Sun',
    1       => 'Mon',
    2       => 'Tue',
    3       => 'Wed',
    4       => 'Thu',
    5       => 'Fri',
    6       => 'Sat',
    7       => 'Sun',
    default => 'Sun',
  }

  # Create a map of the enabled services
  $enabled = {
    "hourly"  => ($retain_hourly > 0),
    "daily"   => ($retain_daily > 0),
    "weekly"  => ($retain_weekly > 0),
    "monthly" => ($retain_monthly > 0),
  }

  # Create a map of the backup time patterns.
  $times = {
    "hourly"  => "${backup_hourly_timer}:${backup_time_minute}",
    "daily"   => "${backup_time_hour}:${minute}",
    "weekly"  => "${day}, ${hour_weekly}:${minute}",
    "monthly" => "*-*-${backup_time_dom} ${hour_monthly}:${minute}",
  }

  # Create and enable the timers.
  $times.each |String $interval, String $time| {
    if $enabled[$interval] {
      $unit  = "rsnapshot-${interval}-${name}.timer"
      file { "${systemd_dir}/${unit}":
        ensure  => file,
        content => epp('rsnapshot/systemd_timer.epp',
          {
            description => "Create an rsnapshot backup for ${name} (${interval})",
            on_calendar => $time,
            unit        => "rsnapshot-${interval}@${name}.service"
          })
      }
      ~> service { $unit: ensure => 'running', enable => true }
    }
  }
}
