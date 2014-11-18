



class utils::transmission{

  package{['transmission-cli', 'transmission-daemon']: }
  service{'transmission-daemon':
    ensure     => running,
    hasrestart => false,
    stop       => "/usr/bin/killall -9 transmission-daemon",
  }

  $settings = hiera_hash('utils::transmission::settings', {})
  $settings_for_transmission = prefix(join_keys_to_values(delete($settings, "rpc-password-clear"), "']/* "), "set dict/entry[. = '")
  augeas{"transmission":
    show_diff => false,
    incl      => "/etc/transmission-daemon/settings.json",
    lens      => "Json.lns",
    changes   => $settings_for_transmission,
    require   => Package['transmission-daemon'],
    notify    => Service['transmission-daemon'],
  }

  $rpc_username = $settings['rpc-username']
  $rpc_port = $settings['rpc-port']
  $rpc_password = $settings['rpc-password-clear']
  $blocklist_url = $settings['blocklist-url']

  # Keep blocklist updated
  if $blocklist_url {
    if $rpc_password {
      $opt_auth = " --auth '${rpc_username}:${rpc_password}'"
    } else {
      $opt_auth = ""
    }
    cron { 'transmission-update-blocklist':
      command => "/usr/bin/transmission-remote http://127.0.0.1:${rpc_port}/transmission${opt_auth} --blocklist-update >/tmp/blocklist.log 2>&1",
      user    => root,
      hour    => 2,
      minute  => 0,
      require => Package['transmission-daemon'],
    }
  }
}
