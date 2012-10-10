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
}
