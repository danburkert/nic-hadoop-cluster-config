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
node /^nic-hadoop-smmc\d+\.nearinfinity\.com$/ {
  include smmc
}

### Individual SMMC nodes
node 'nic-hadoop-smmc01.nearinfinity.com' {
  require smmc
  include hadoop::namenode
}
node 'nic-hadoop-smmc02.nearinfinity.com' {
  require smmc
  include hadoop::jobtracker
}
node 'nic-hadoop-smmc03.nearinfinity.com' {
  require smmc
  include zookeeper::server
}
node 'nic-hadoop-smmc04.nearinfinity.com' {
  require smmc
  include hadoop::secondarynamenode
}
node 'nic-hadoop-smmc05.nearinfinity.com' {
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
  package { 'hadoop-0.20': }
  package { 'hadoop-0.20-sbin': }
  package { 'hadoop-0.20-native': }
  file { 'hadoop-conf':
    path    => '/etc/hadoop-0.20/conf.nic-hadoop/',
    ensure  => present,
    source  => 'puppet:///repo/conf.nic-hadoop/',
    recurse => true,
    require => Package['hadoop-0.20'],
  }
  exec { 'hadoop-alternatives':
    command => '/usr/sbin/alternatives --install /etc/hadoop-0.20/conf hadoop-0.20-conf /etc/hadoop-0.20/conf.nic-hadoop 100',
    require => File['hadoop-conf'],
  }
  file { [ '/data1/hdfs'
         , '/data2/hdfs'
         ]:
    ensure  => directory,
    owner   => 'hdfs',
    group   => 'hadoop',
    mode    => '700',
    require => Package['hadoop-0.20'],
  }
  service { 'iptables':
    ensure => stopped,
    enable => false,
  }
}
class hadoop::datanode {
  require hadoop
  package { 'hadoop-0.20-datanode': }
  file { [ '/data1/hdfs/data'
         , '/data2/hdfs/data'
         ]:
    ensure  => directory,
    owner   => 'hdfs',
    group   => 'hadoop',
    mode    => '700',
    require => Package['hadoop-0.20-datanode'],
  }
  service { 'hadoop-0.20-datanode':
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require    => Package['hadoop-0.20-datanode'],
  }
}
class hadoop::namenode {
  require hadoop
  package { 'hadoop-0.20-namenode': }
  service { 'hadoop-0.20-namenode':
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require    => Package['hadoop-0.20-namenode'],
  }
}
class hadoop::secondarynamenode {
  require hadoop
  package { 'hadoop-0.20-secondarynamenode': }
  service { 'hadoop-0.20-secondarynamenode':
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require    => Package['hadoop-0.20-secondarynamenode'],
  }
}
class hadoop::tasktracker {
  require hadoop
  package { 'hadoop-0.20-tasktracker': }
  file { [ '/data1/mapred'
         , '/data2/mapred'
         , '/data1/mapred/local/'
         , '/data2/mapred/local/'
         ]:
    ensure  => directory,
    owner   => 'mapred',
    group   => 'hadoop',
    mode    => '755',
    require => Package['hadoop-0.20-tasktracker'],
  }
  service { 'hadoop-0.20-tasktracker':
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require    => Package['hadoop-0.20-tasktracker'],
  }
}
class hadoop::jobtracker {
  require hadoop
  package { 'hadoop-0.20-jobtracker': }
  service { 'hadoop-0.20-jobtracker':
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require    => Package['hadoop-0.20-jobtracker'],
  }
}

### Setup HBase ###
class hbase {
  require hadoop
  require zookeeper
  package { 'hadoop-hbase': }
  file { 'hbase-conf':
    path    => '/etc/hbase/conf/',
    ensure  => present,
    source  => 'puppet:///repo/conf.nic-hbase/',
    recurse => true,
    require => Package['hadoop-hbase'],
  }
}
class hbase::regionserver {
  require hbase
  package { 'hadoop-hbase-regionserver': }
  service { 'hadoop-hbase-regionserver':
    require => Package['hadoop-hbase-regionserver'],
  }
}
class hbase::master {
  require hbase
  package { 'hadoop-hbase-master': }
  service { 'hadoop-hbase-master':
    require => Package['hadoop-hbase-master'],
  }
}

### Setup Zookeeper ###
class zookeeper {
  require hadoop
  package { 'hadoop-zookeeper': }
  file { '/etc/hadoop-zookeeper/':
    ensure => directory,
    require => Package['hadoop-zookeeper'],
  }
  file { 'zookeeper-conf':
    path    => '/etc/hadoop-zookeeper/conf.nic-zookeeper/',
    ensure  => present,
    source  => 'puppet:///repo/conf.nic-zookeeper/',
    recurse => true,
    require => File['/etc/hadoop-zookeeper/'],
  }
  exec { 'zookeeper-alternatives':
    command => '/usr/sbin/alternatives --install /etc/zookeeper hadoop-zookeeper-conf /etc/hadoop-zookeeper/conf.nic-zookeeper 100',
    require => File['zookeeper-conf'],
  }
}
class zookeeper::server {
  require zookeeper
  package { 'hadoop-zookeeper-server': }
  # The zookeeper service that comes installed does not work, so create a new one
  # based off the zkServer script.
  file { '/etc/init.d/zookeeper':
    ensure  => present,
    source  => '/usr/bin/zookeeper-server',
    mode    => '755',
    require => Package['hadoop-zookeeper-server'],
  }
  exec { 'add chkconfig info':
    command => "/bin/echo '# chkconfig: 2345 85 15' >> /etc/init.d/zookeeper",
    require => File['/etc/init.d/zookeeper'],
  }
  service { 'zookeeper':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require    => exec['add chkconfig info'],
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
    require => user['localadmin']
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
