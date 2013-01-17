# Class: puppet::dashboard
# Used the puppetlabs code to merge their dashboard into the basic cisco puppet module
#
class puppet::dashboard (
  $dashboard_ensure         = $puppet::dashboard::params::dashboard_ensure,
  $dashboard_user           = $puppet::dashboard::params::dashboard_user,
  $dashboard_group          = $puppet::dashboard::params::dashboard_group,
  $dashboard_password       = $puppet::dashboard::params::dashboard_password,
  $dashboard_db             = $puppet::dashboard::params::dashboard_db,
  $dashboard_charset        = $puppet::dashboard::params::dashboard_charset,
  $dashboard_site           = $puppet::dashboard::params::dashboard_site,
  $dashboard_port           = $puppet::dashboard::params::dashboard_port,
  $dashboard_config         = $puppet::dashboard::params::dashboard_config,
  $mysql_root_pw            = $puppet::dashboard::params::mysql_root_pw,
  $passenger                = true,
  $mysql_package_provider   = $puppet::dashboard::params::mysql_package_provider,
  $ruby_mysql_package       = $puppet::dashboard::params::ruby_mysql_package,
  $dashboard_config         = $puppet::dashboard::params::dashboard_config,
  $dashboard_root           = $puppet::dashboard::params::dashboard_root,
  $rack_version             = $puppet::dashboard::params::rack_version
) inherits puppet::dashboard::params {

  require mysql

  class { 'mysql::ruby':
    package_provider => $mysql_package_provider,
    package_name     => $ruby_mysql_package,
  }

  if $passenger {
    class { 'puppet::dashboard::passenger':
      dashboard_site   => $dashboard_site,
      dashboard_port   => $dashboard_port,
      dashboard_config => $dashboard_config,
      dashboard_root   => $dashboard_root,
      require          => Package['puppetmaster-passenger']
    }
  }

  package { $dashboard_package:
    ensure  => $dashboard_version,
    require => [ Package['rdoc'], Package['rack']],
  }

  # Currently, the dashboard requires this specific version
  #  of the rack gem. Using the gem provider by default.
  package { 'rack':
    ensure   => $rack_version,
    provider => 'gem',
  }

  package { ['rake', 'rdoc']:
    ensure   => present,
    provider => 'gem',
  }

  File {
    mode    => '0755',
    owner   => $dashboard_user,
    group   => $dashboard_group,
    require => Package[$dashboard_package],
  }

  file { [ "${puppet::dashboard::params::dashboard_root}/public", "${puppet::dashboard::params::dashboard_root}/tmp", "${puppet::dashboard::params::dashboard_root}/log", '/etc/puppet-dashboard', "${puppet::dashboard::params::dashboard_root}/spool" ]:
    ensure       => directory,
    recurse      => true,
    recurselimit => '1',
  }

  file {'/etc/puppet-dashboard/database.yml':
    ensure  => present,
    content => template('puppet/database.yml.erb'),
  }

  file { "${puppet::dashboard::params::dashboard_root}/config/database.yml":
    ensure => 'symlink',
    target => '/etc/puppet-dashboard/database.yml',
  }

  file { [ "${puppet::dashboard::params::dashboard_root}/log/production.log", "${puppet::dashboard::params::dashboard_root}/config/environment.rb" ]:
    ensure => file,
    mode   => '0644',
  }

  file { '/etc/logrotate.d/puppet-dashboard':
    ensure  => present,
    content => template('puppet/logrotate.erb'),
    owner   => '0',
    group   => '0',
    mode    => '0644',
  }

  exec { 'db-migrate':
    command => 'rake RAILS_ENV=production db:migrate',
    cwd     => $puppet::dashboard::params::dashboard_root,
    path    => '/usr/bin/:/usr/local/bin/',
    creates => "/var/lib/mysql/${dashboard_db}/nodes.frm",
    require => [Package[$dashboard_package], Mysql::Db[$dashboard_db],
                File["${puppet::dashboard::params::dashboard_root}/config/database.yml"]],
  }

  mysql::db { $dashboard_db:
    user     => $dashboard_user,
    password => $dashboard_password,
    host     => localhost,
    charset  => $dashboard_charset,
  }

  user { $dashboard_user:
      ensure     => 'present',
      comment    => 'Puppet Dashboard',
      gid        => $dashboard_group,
      shell      => '/sbin/nologin',
      managehome => true,
      home       => "/home/${dashboard_user}",
  }

  group { $dashboard_group:
      ensure => 'present',
  }
}

