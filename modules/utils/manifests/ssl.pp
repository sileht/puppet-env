

class utils::ssl{

  ensure_packages(['ssl-cert'])

  file{'/etc/ssl/private':
    ensure  => directory,
    owner   => 'root',
    group   => 'ssl-cert',
    mode    => '0750',
    require => Package['ssl-cert'],
  }
  file{'/etc/ssl/public':
    ensure  => directory,
    owner   => 'root',
    group   => 'ssl-cert',
    mode    => '0755',
    require => Package['ssl-cert'],
  }

  create_resources(utils::ssl::certs, hiera_hash('utils::ssl::certs'), {})
}

define utils::ssl::certs($cert, $key, $ca){
  file{"/etc/ssl/private/$name.pem":
    content => "$cert$key",
    owner   => 'root',
    group   => 'ssl-cert',
    mode    => '0640',
    require => File['/etc/ssl/private']
  }
  file{"/etc/ssl/private/$name.key":
    content => $key,
    owner   => 'root',
    group   => 'ssl-cert',
    mode    => '0640',
    require => File['/etc/ssl/private']
  }
  file{"/etc/ssl/public/$name.crt":
    content => "$cert$ca",
    owner   => 'root',
    group   => 'ssl-cert',
    mode    => '0644',
    require => File['/etc/ssl/public']
  }
  file{"/etc/ssl/certs/$name.ca":
    content => $ca,
    owner   => 'root',
    group   => 'ssl-cert',
    mode    => '0644',
  }
}
