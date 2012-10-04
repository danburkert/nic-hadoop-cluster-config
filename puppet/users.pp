user { 'localadmin':
    ensure => present,
    password => 'localadmin',
    gid => 'localadmin',
    require => Group['localadmin'],
}

group { 'localadmin':
    ensure => present,
}
