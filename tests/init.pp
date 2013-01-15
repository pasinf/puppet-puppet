$mysql_root_password = "changeme"
$mysql_puppet_password = "changeme"

class { 'puppet': 
  run_master           => true,
  run_agent            => true,
  puppetmaster_address => "$::fqdn",
  master_autosign_cert => false,
  certname             => "$::fqdn",
  runinterval          => '600',
  mysql_root_password  => $mysql_root_password,
  mysql_password       => $mysql_puppet_password,
  report_enable        => true,
  reports              => "http, store",
  report_url           => 'http://127.0.0.1:8080/reports/upload',
}
