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
node 'nic-hadoop-smmc05.hadoop.nearinfinity.com' {
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
# ssh_authorized_key { "hadoop":
#   ensure  => "present",
#   type    => "ssh-rsa",
#   key     => "AAAAB3NzaC1yc2EAAAADAQABAAABAQC1Rt6OEzmuG1pKgMP46N6e1SSn2EjeBXlTw++fRzRUYWePzygIVGb+o/sFw52Sa7cNxh11AZuiu4Bh/GzK9GbsCsFD6prayYmTmNIDgUr4RfPWfVnSmXwy4ipfRNh3fWK+VxLC00vLvSEY9DbdoftjjD6HAKzjh8QltVXQbtsJ47+oxpGgUvTMWbAQ1usz7z/kwbBllVBkCabwKP4km9ZwkpdsZC9IEAJ+bbrFEeqpD4W7qp/fUIjmx5ogfxhJA8c0EmuWcG0YlLNPBgZVSx1+wwgceM2oppOqsOJUmkL3TRm3E1JuX+PSsBfEoLtgW8bXzlO0JLH6d40UA7P8DH+J",
#   user    => "hadoop",
#   require => User['hadoop'],
# }
# file { 'ssh-key':
#   ensure  => present,
#   path    => '/home/hadoop/.ssh/id_rsa',
#   source  => 'puppet:///private/hadoop-id_rsa',
#   require => Ssh_authorized_key['hadoop'],
# }
# file { 'ssh-key-pub':
#   ensure  => present,
#   path    => '/home/hadoop/.ssh/id_rsa.pub',
#   source  => 'puppet:///private/hadoop-id_rsa.pub',
#   require => Ssh_authorized_key['hadoop'],
# }
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
    key     => "aaaab3nzac1yc2eaaaabiwaaaqeaqw/odnye2rrgwz0ydp1unowqcrc4czp8llvpefecq9np+a4fot4hoc3acbcpq49ofv4y2100tzkgl6sbnjvt+enzszfjqz43qixclyq5jejhu/2yc/pgp/svxhmgiinknpwjn8erbur0oejthk2fifkqvxxntvykysfwsu8mrvetxvga7/cqssscwp5nik15vqymarvu/uliecki/mcksptuk/2xc27fwgtu82tqundc+naaa5yjx8chvt95bm7g9u4bxjgdya6fufa56mkhn6rwohtwcqe17e30oeirypp3yt7/rxqyzvgug3++tejoftclmuqgxys/tj5kgwjcow",
    user    => "localadmin",
    require => user['localadmin']
  }
  ssh_authorized_key { "localadmin":
    ensure  => "present",
    type    => "ssh-rsa",
    key     => "AAAAB3NzaC1yc2EAAAADAQABAAABAQC5GHZ5bxtta63uk4uQwI895V6pQs39uKAnE+mHQf7KjctVvp57caYYxUNCwNHflLmFBMj+EDjtSgMmPv7GPKgPzsBPQoWT9pqErGhBSL3GQsFn1qmfBjhsySIzE70tseq6okVwFxR/BjzgdGePwC3pyCsAqKuz0IXYJMqwzGqse83K4JQ1mZ/LyaP6M+/OGBENWG/1XEvcX6v/t1sWq+Nf0hJwVstSSP1j2W6gCAMuUkMaplbf/QoVt3ld0xDyQOOkgFfplVGmFVXalaQuqUAF9mHhUnHh+96BFX4uaCTV4s41yP5MJbftnXrF5H3orb6E+yICb4ZNtanJ6cd+AyU3",
    user    => "localadmin",
    require => user['localadmin']
  }
  file { 'ssh-key':
    ensure  => present,
    path    => '/home/localadmin/.ssh/id_rsa',
    source  => 'puppet:///private/localadmin-id_rsa',
    require => Ssh_authorized_key['localadmin'],
  }
  file { 'ssh-key-pub':
    ensure  => present,
    path    => '/home/localadmin/.ssh/id_rsa.pub',
    source  => 'puppet:///private/localadmin-id_rsa.pub',
    require => Ssh_authorized_key['localadmin'],
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
