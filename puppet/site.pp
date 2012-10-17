# etc/puppet/manifests/site.pp

# This manifest relies on the following modules:
# puppetlabs/razor
# puppetlabs/vcsrepo
# razorsedge/network
# saz/sudo

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
  include hadoop::namenode
}
node 'nic-hadoop-smmc02.hadoop.nearinfinity.com' {
  require smmc
  include hadoop::jobtracker
}
node 'nic-hadoop-smmc03.hadoop.nearinfinity.com' {
  require smmc
  include zookeeper::server
}
node 'nic-hadoop-smmc04.hadoop.nearinfinity.com' {
  require smmc
  include hadoop::namenode
}
node 'nic-hadoop-smmc04.hadoop.nearinfinity.com' {
  require smmc
  include hbase::master
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
  require config-files
  group { 'hadoop':
    ensure => present,
  }
  user { 'hadoop':
      ensure     => present,
      gid        => 'hadoop',
      managehome => true,
      require    => Group['hadoop'],
  }
  ssh_authorized_key { "hadoop":
    ensure  => "present",
    type    => "ssh-rsa",
    key     => "AAAAB3NzaC1yc2EAAAADAQABAAABAQDfGPHgjqtE4gfbSHPa3vYY8W6zmshj7KoTDMFS14iYBtNCwEUim1oUAKRQhHy8NIyjXpkZV0uZVmSXbRSBM+OOSeUgBziryKGYa3pQoHcOW68SaOMgw/L03nXHFHIIjv64MB8ErhOt6JyEoH23XEh7WZxHdgJPeVEyPxZYRrYJQ2gSmJcv3r3x0AhULJW3WGW/Ud54sB1Zh4iqC6ED26Lzpn2xWqaQyeyyWOV7W+6SPXKT9ku08VcD+AvUtqTVC+yjSmUwDBNNEaqL+MtopWyatMheZFmu+YaisvTNvZSiHTTwfRsbTW9P9RDKfT4FZmQhBjahLOUe3qtpZhScO5Yf==",
    user    => "hadoop",
    require => File['ssh-dir']
  }
  file { 'ssh-dir':
    ensure => present,
    path   => "/home/hadoop/.ssh/",
  }
  file { 'ssh-key':
    ensure  => present,
    path    => '/home/hadoop/.ssh/id_rsa',
    source  => 'puppet:///private/id_rsa',
    require => File['ssh-dir'],
  }
  package { 'hadoop-0.20': }
  package { 'hadoop-0.20-sbin': }
  package { 'hadoop-0.20-native': }
  exec { '/bin/chown hadoop:hadoop -R /usr/lib/hadoop-0.20':
    require => [Package['hadoop-0.20'], User['hadoop']],
  }
  file { '/usr/lib/hadoop-0.20/conf':
    ensure  => directory,
    source  => '/home/localadmin/cluster-config/hadoop-conf',
    recurse => true,
    purge   => true,
    owner   => 'hadoop',
    group   => 'hadoop',
    require => [Package['hadoop-0.20'], User['hadoop']],
  }
}
class hadoop::datanode {
  require hadoop
  package { 'hadoop-0.20-datanode': }
}
class hadoop::namenode {
  require hadoop
  package { 'hadoop-0.20-namenode': }
}
class hadoop::tasktracker {
  require hadoop
  package { 'hadoop-0.20-tasktracker': }
}
class hadoop::jobtracker {
  require hadoop
  package { 'hadoop-0.20-jobtracker': }
}

### Setup HBase ###
class hbase {
  require hadoop
  require zookeeper
  package { 'hadoop-hbase': }
  exec { '/bin/chown hadoop:hadoop -R /usr/lib/hbase':
    require => Package['hadoop-hbase'],
  }
  file { '/usr/lib/hbase/conf':
    ensure  => directory,
    source  => '/home/localadmin/cluster-config/hbase-conf',
    recurse => true,
    purge   => true,
    owner   => 'hadoop',
    group   => 'hadoop',
    require => Package['hadoop-hbase'],
  }
}
class hbase::regionserver {
  require hbase
  package { 'hadoop-hbase-regionserver': }
}
class hbase::master {
  require hbase
  package { 'hadoop-hbase-master': }
}

### Setup Zookeeper ###
class zookeeper {
  require hadoop
  package { 'hadoop-zookeeper': }
  exec { '/bin/chown hadoop:hadoop -R /usr/lib/zookeeper':
    require => Package['hadoop-zookeeper'],
  }
  file { '/usr/lib/zookeeper/conf':
    ensure  => directory,
    source  => '/home/localadmin/cluster-config/zookeeper-conf',
    recurse => true,
    purge   => true,
    owner   => 'hadoop',
    group   => 'hadoop',
    require => Package['hadoop-zookeeper'],
  }
}
class zookeeper::server {
  require zookeeper
  package { 'hadoop-zookeeper-server': }
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

class config-files {
  require localadmin
  package { 'git': }
  vcsrepo { '/home/localadmin/cluster-config':
    ensure   => latest,
    provider => git,
    source   => 'https://github.com/danburkert/nic-hadoop-cluster-config.git',
    revision => 'master',
    require  => Package['git'],
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
    source  => "puppet:///private/jdk-7u7-linux-x64.rpm",
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
