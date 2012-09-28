file {'/tmp/test1':
  ensure  => present,
  content => "Hi!\n",
}

file {'/tmp/test2':
  ensure => directory,
  mode   => 0644,
}

file {'/tmp/test3':
  ensure => link,
  target => '/tmp/test1',
}

notify{"I'm notifying you!\n":}
notify{"So am I!\n":}
