node 'nic-hadoop-razor.nearinfinity.com' {
  class { 'sudo':
    config_file_replace => false,
  }

  class { 'razor':
    username => 'razor',
  }

  class { 'tftp':
    inetd => false,
  }
  exec { 'razor-mk_uri':
    command => "/bin/sed -i'' -e 's|mk_uri: http://.*:8026|mk_uri: http://${razor::address}:8026|' /opt/razor/conf/razor_server.conf",
    unless => "/bin/grep -q 'mk_uri: http://${razor::address}:8026' /opt/razor/conf/razor_server.conf",
    require => Service['razor'],
    notify => Exec['restart-razor'],
  }
  exec { 'restart-razor':
    command => "/opt/razor/bin/razor_daemon.rb restart",
  }
}

node /^nic-hadoop-smmc\d+\.hadoop\.nearinfinity\.com$/ {
  notify { 'log message':
    message => "Puppet agent run on machine ${hostname}",
  }

  user { 'localadmin':
      ensure => present,
      password => 'localadmin',
      gid => 'localadmin',
  }

  group { 'localadmin':
      ensure => present,
  }

  Group['localadmin'] -> User['localadmin']

  user { 'hadoop':
      ensure => present,
      gid => 'hadoop',
  }

  group { 'hadoop':
      ensure => present,
  }

  Group['hadoop'] -> User['hadoop']


  network::bond::dynamic { "bond0":
    ensure => "up",
  }
  network::bond::slave { "eth0":
    macaddress => $macaddress_eth0,
    master => "bond0",
  }
  network::bond::slave { "eth1":
    macaddress => $macaddress_eth1,
    master => "bond0",
  }

}
