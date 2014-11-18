class utils (
  $mailredirect = true,
  $supervisor = false,
){

  Exec { path => ["/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }
  Package { ensure => 'latest' }

  exec {'systemctl-daemon-reload':
    refreshonly => true,
    command => '/bin/systemctl daemon-reload',
  }

  service{'puppet': ensure => stopped, enable => false}
  service{'cron': ensure => running, enable => true}
  service{'rsyslog': ensure => running, enable => true}
  tidy { 'puppet::reports':
    path => "/var/cache/puppet/reports/$::fqdn",
    matches => '*',
    age => '7d',
    backup => false,
    recurse => true,
    rmdirs => true,
    type => 'ctime',
  }

  create_resources(package, convert_nil_to_hash(hiera_hash('utils::packages', {})))
  create_resources(apt::source, hiera_hash('utils::apt_sources', {}))
  create_resources(apt::pin, hiera_hash('utils::apt_pins', {}))
  create_resources(service, convert_nil_to_hash(hiera_hash('utils::services', {})))
  create_resources(utils::mount, convert_nil_to_hash(hiera_hash('utils::mounts', {})))
  create_resources(kmod::install, convert_nil_to_hash(hiera_hash('utils::modules', {})))
  create_resources(cron, hiera_hash('utils::crons', {}))
  create_resources(openvpn::ca, hiera_hash('openvpn::cas', {}))
  create_resources(file, prep_file_hash_with_content(hiera_hash('utils::files', {})))
  create_resources(file_line, hiera_hash('utils::file_lines', {}))
  create_resources(utils::app, convert_nil_to_hash(hiera_hash('utils::apps', {})))
  create_resources(ssh_authorized_key, hiera_hash('utils::ssh_authorized_key', {}))
  create_resources(supervisor::service, hiera_hash('utils::supervisor::services', {}))
  create_resources(mysql::db, hiera('mysql::server::db', {}))

  Apt::Source <| |> -> Package <| |>
  /*if $mailredirect {
    class {'utils::mailredirect': }
  }*/

  if $supervisor {
    class { 'supervisor':
        conf_dir => '/etc/supervisor/conf.d',
        conf_ext =>  '.conf',
    }
  }

  $files = hiera_array('utils::deletes')
  file{$files: ensure => absent, force  => 'true', recurse => 'true' }

  package{'lvm2':}
  exec{'lvm-lenses-update':
    command => '/usr/bin/wget https://raw.githubusercontent.com/hercules-team/augeas/master/lenses/lvm.aug -O /usr/share/augeas/lenses/dist/lvm.aug',
    unless  => "/usr/bin/md5sum /usr/share/augeas/lenses/dist/lvm.aug | /bin/grep -nq 012cdac3984ac7bee79cce56a3625d7e",
    require => Package['wget'],
  }
  augeas{'lvm':
    context => '/files/etc/lvm/lvm.conf',
    changes => ['set devices/dict/issue_discards/int 1'],
    require => [Package['lvm2'], Exec['lvm-lenses-update']],
  }

  Package{ require => User['sileht'] }

  group{'sileht': gid => 1000}
  user{'sileht':
    uid        => 1000,
    gid        => 1000,
    shell      => "/usr/bin/zsh",
    require    => Group['sileht'],
  }
  user{'root':
    ensure         => present,
    purge_ssh_keys => true,
    home           => '/root',
  }
}

define utils::app($service = undef, $conf_files = {}, $conf_lines = {}){
  package{$name:}
  $service_props = merge(string_to_hash(pick($service, $name) , 'name'), {
    require => Package[$name],
  })
  $service_name = $service_props['name']
  ensure_resource(service, $service_name, $service_props)

  $mod_conf_files = inject_in_hashes($conf_files, {
    require => Package[$name],
    notify  => Service[$service_name],
    })
  create_resources(file, prep_file_hash_with_content($mod_conf_files))

  $mod_conf_lines = inject_in_hashes($conf_lines, {
    require => Package[$name],
    notify  => Service[$service_name],
    })
  create_resources(file_line, $mod_conf_lines)
}

define utils::mount($device, $fstype, $pass=0, $options=['default']){
  # this define wraps the 'mount' type with reasonable defaults
  # make sure the parent of the mountpoint exists - there's no 'mkdir -p' equivalent in puppet
  # note this only makes two levels of directories deep - mount point and its immediate parent
  $parentpath = inline_template("<%= arry = @name.split('/'); if arry.length > 2; arry.slice(0..-2).join('/'); else @name end %>")

  if ! defined(File["$parentpath"]) {
    file { "$parentpath":  ensure => directory }
  }

  # make sure the mountpoint exists, create it as a directory if not
  if ! defined(File[$name]) {
    file { $name: ensure => directory }
  }

  mounttab { $name:
    device      => $device,
    options     => $options,
    ensure      => present,
    blockdevice => "-",
    fstype      => $fstype,
    pass        => $pass,
    dump        => 0,
    atboot      => "yes",
    notify      => Mountpoint[$name],
  }

  mountpoint { $name:
    require  => [ Mounttab[$name], File[$name] ],
    device   => $device,
    options  => $options,
    remounts => false,
    ensure   => present,
  }
}


