### Razor node
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

### All SMMC nodes
node /^nic-hadoop-smmc\d+\.hadoop\.nearinfinity\.com$/ {
  include smmc
}

### Individual SMMC nodes
node 'nic-hadoop-smmc01.hadoop.nearinfinity.com' {
  require smmc
  include zookeeper::server
  include hadoop::namenode
  include hadoop::jobtracker
}
node 'nic-hadoop-smmc02.hadoop.nearinfinity.com' {
  require smmc
  include hadoop::namenode
}
node 'nic-hadoop-smmc03.hadoop.nearinfinity.com' {
  require smmc
  include hadoop::jobtracker
}

### SMMC Setup ###
class smmc {
  include interface-bond
  include java
  include localadmin
  include hadoop
  include hadoop::datanode
  include hadoop::tasktracker
  include hbase
  include hbase::regionserver
}

### Hadoop Setup ###
class cdh::repo {
  yumrepo { 'cloudera-cdh3':
    baseurl    => 'http://archive.cloudera.com/redhat/6/x86_64/cdh/3/',
    mirrorlist => 'http://archive.cloudera.com/redhat/6/x86_64/cdh/3/mirrors',
    gpgkey     => 'http://archive.cloudera.com/redhat/6/x86_64/cdh/RPM-GPG-KEY-cloudera',
    gpgcheck   => 1,
  }
}

class hadoop {
  require cdh::repo
  package { 'hadoop-0.20': }
  package { 'hadoop-0.20-sbin': }
  package { 'hadoop-0.20-native': }
}
class hadoop::datanode {
  require hadoop
  package { 'hadoop-0.20-datanode': }
  service { 'hadoop-0.20-datanode':
    ensure      => running,
    enable      => true,
    hasstatus   => true,
    hasrestart  => true,
  }
}
class hadoop::namenode {
  require hadoop
  package { 'hadoop-0.20-namenode': }
  service { 'hadoop-0.20-namenode':
    ensure      => running,
    enable      => true,
    hasstatus   => true,
    hasrestart  => true,
  }
}
class hadoop::tasktracker {
  require hadoop
  package { 'hadoop-0.20-tasktracker': }
  service { 'hadoop-0.20-tasktracker':
    ensure      => running,
    enable      => true,
    hasstatus   => true,
    hasrestart  => true,
  }
}
class hadoop::jobtracker {
  require hadoop
  package { 'hadoop-0.20-jobtracker': }
  service { 'hadoop-0.20-jobtracker':
    ensure      => running,
    enable      => true,
    hasstatus   => true,
    hasrestart  => true,
  }
}

### Setup HBase ###
class hbase {
  require hadoop
  package { 'hadoop-hbase': }
}
class hbase::regionserver {
  require hbase
  package { 'hadoop-hbase-regionserver': }
  service { 'hadoop-hbase-regionserver':
    ensure      => running,
    enable      => true,
    hasstatus   => true,
    hasrestart  => true,
  }
}
class hbase::master {
  require hbase
  package { 'hadoop-hbase-master': }
  service { 'hadoop-hbase-master':
    ensure      => running,
    enable      => true,
    hasstatus   => true,
    hasrestart  => true,
  }
}

### Setup Zookeeper ###
class zookeeper {
  require hadoop
  package { 'hadoop-zookeeper': }
}
class zookeeper::server {
  require zookeeper
  package { 'hadoop-zookeeper-server': }
  service { 'hadoop-zookeeper-server':
    ensure      => running,
    enable      => true,
    hasstatus   => true,
    hasrestart  => true,
  }
}

class localadmin {
  group { 'localadmin':
    ensure => present,
  }
  user { 'localadmin':
      ensure     => present,
      gid        => 'localadmin',
      managehome => true,
      require    => Group['localadmin'],
  }
  ssh_authorized_key { "dburkert":
    ensure  => "present",
    type    => "ssh-rsa",
    key     => "AAAAB3NzaC1yc2EAAAABIwAAAQEAqW/oDNyE2RrGwZ0ydP1UnOWqCRc4czp8lLvPefecQ9nP+a4FOt4hOC3AcbcpQ49OfV4Y2100tZKgL6SBnJVT+eNzsZfjqz43QiXClyq5jEJhU/2yC/pgp/sVXhMGIinKNpwJn8eRbur0oejThK2FifKqvXxNtvyKySfWSu8MRvETXvGA7/cqSSScwp5nik15vQYmarvu/ulIECki/MCksPtuk/2xC27fWgTU82tqundc+NAaa5YJX8chVT95BM7g9u4BxjgDYA6FuFa56MKHN6RwOHTwcQe17e30Oeirypp3yt7/RxqYZVgug3++tEjOftcLmUQGXYS/Tj5KGWJcOw==",
    user    => "localadmin",
    require => User['localadmin']
  }
  class { 'sudo': }
  sudo::conf { 'localadmin':
    content  => "%localadmin ALL=(ALL) NOPASSWD: ALL\n",
  }
}

class java {
  file { "rpm-dir":
    ensure => directory,
    path => "/opt/rpm",
  }
  file { "jdk-rpm":
    ensure  => present,
    path    => "/opt/rpm/jdk-7u7-linux-x64.rpm",
    source  => "puppet:///rpm/jdk-7u7-linux-x64.rpm",
    require => File['rpm-dir'],
  }
  package { 'jdk-1.7.0_07-fcs.x86_64':
    ensure   => installed,
    provider => rpm,
    source   => '/opt/rpm/jdk-7u7-linux-x64.rpm',
    require  => File['jdk-rpm'],
  }
}

class interface-bond {
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
