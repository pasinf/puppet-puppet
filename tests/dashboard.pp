mysql_root_password = "changeme"

class { 'puppet::dashboard': 
  dashboard_ensure     => present,
  dashboard_user       => "dashboard",
  dashboard_group      => "dashboard",
  dashboard_password   => "changeme",
  dashboard_db         => "puppet-dashboard",
  dashboard_site       => "$::fqdn",
  mysql_root_pw        => "$mysql_root_password",
}
