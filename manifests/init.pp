class puppet(
  $run_master = false,
  $run_agent = false,
  $puppetmaster_address = "",
  $certname = "",
  $master_autosign_cert = undef,
  $runinterval = 120,
  $report_url = "http://127.0.0.1:8080/reports/upload",
  $reports,
  $report_enable = true,
  $extra_modules = "",
  $mysql_root_password = 'changeme',
  $mysql_password = 'changeme',
) {

  package { puppet-common:
    ensure => present
  }
# install latest facter version due to issues with ubuntu one
  package { 'facter':
    ensure => latest
  }
  if ($run_master) {
# run master under passenger
    package { "puppetmaster-passenger":
      ensure => present
    }

    apache::vhost { 'puppetmaster':
      priority           => '20',
      port               => '8140',
      docroot            => '/usr/share/puppet/rack/puppetmasterd/public/',
      template           => 'puppet/puppetmaster-vhost.erb',
      configure_firewall => false,
    }

# set up mysql server
    class { 'mysql::server':
      config_hash => {
        'root_password' => $mysql_root_password,
        'bind_address'  => '127.0.0.1'
      }
    }

    mysql::db { 'puppet':
      user         => puppet,
      password     => $mysql_password,
      host         => localhost,
    }
    package { 'ruby-activerecord':
      ensure => present
    }

    package { 'ruby-mysql':
      ensure => present
    }

    File <| title == '/etc/puppet/puppet.conf' |> {
      notify +> Exec["restart-puppetmaster"]
    }

    file { '/etc/puppet/autosign.conf':
      ensure  => present,
      content => template('puppet/autosign.conf.erb'),
    }

    exec { 'restart-puppetmaster':
      command     => "/usr/sbin/service apache2 restart",
      require     => Package["puppetmaster-passenger"],
      refreshonly => true
    }

    if $report_enable {
      file { '/var/lib/puppet/reports':
        ensure => directory,
        mode   => 0750,
        owner  => puppet,
        group  => puppet,
      }
    }

  }

  if ($run_agent) {
    package { puppet:
      ensure => present
    }

    file { '/etc/default/puppet':
      content => template('puppet/defaults.erb'),
      notify  => Exec["restart-puppet"],
    }

    File <| title == '/etc/puppet/puppet.conf' |> {
      notify +> Exec["restart-puppet"]
    }

    file { '/etc/init.d/puppet':
      mode    => 0755,
      owner   => root,
      group   => root,
      content => template('puppet/init.erb'),
      notify  => Exec["restart-puppet"]
    }

    exec { 'restart-puppet':
      command => "/usr/sbin/service puppet restart",
      require => Package[puppet],
      refreshonly => true
    }

  }

  file { '/etc/puppet/puppet.conf':
    content => template('puppet/puppet.conf.erb'),
    require => Package[puppet-common]
  }
}
