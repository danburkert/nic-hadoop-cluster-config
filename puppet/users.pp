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
