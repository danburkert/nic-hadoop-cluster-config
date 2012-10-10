node 'nic-hadoop-razor.nearinfinity.com' {
  class { 'sudo':
    config_file_replace => false,
  }

  class { 'razor':
    address => '192.168.203.12',
  }

  class { 'tftp':
    inetd => false,
  }
}

node /^smmc\d+\.nearinfinity\.com$/ {
  notify { 'log message':
    message => "Puppet agent run on machine " + $hostname,
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
