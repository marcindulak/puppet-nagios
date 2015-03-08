# nagios server
$server = "nagiosserver"
# nagios configuration directory must be consistent across exported resources
#$sysconfdir = "/etc/nagios3"  # Debian/Ubuntu
$sysconfdir = "/etc/nagios"  # RHEL/Fedora
#$sysconfdir = "/usr/local/etc/nagios"  # FreeBSD
# RHEL SELinux blocks NRPE in directories other than /etc/nrpe.d
$nrpe_incdir = "/etc/nrpe.d"

# all hosts groups: group hosts by their purpose
$nagios_hostgroup_all = "batch-servers, database-servers, file-servers, web-servers"

# RHEL6 (32-bit) nagios client
node "rhel6" {
  Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }
  class { "nagios": server_custom => $server,
    sysconfdir_custom => "$sysconfdir",
    user1_custom => "/usr/lib/nagios/plugins",  # PATH to plugins on RHEL 32-bit
    nrpe_dont_blame_nrpe_custom => 1,
    nrpe_incdir_custom => "$nrpe_incdir",
  } ->
  class { "nagios::nrpe_incdir": } ->  # needed only on the client
  class { "nagios::client": } ->
  # Define hostgroups this host belongs to
  class { "nagios::host": hostgroups => "web-servers" }
  # NRPE commands need to be defined on the nagios client!
  # https://bugs.launchpad.net/ubuntu/+source/nagios-plugins/+bug/615848
  nagios::command {"check_disk": command_name => "check_disk",
    command_line => "${nagios::user1}/check_disk -w \$ARG1\$ -c \$ARG2\$ -p \$ARG3\$ -X devtmpfs -X tmpfs -A -i /sys/fs/pstore -i /sys/kernel/config",
    exported_resource => false,
  }
}

# RHEL7 nagios client
node "rhel7" {
  Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }
  class { "nagios": server_custom => $server,
    sysconfdir_custom => "$sysconfdir",
    user1_custom => "/usr/lib64/nagios/plugins",  # PATH to plugins on RHEL 64-bit
    nrpe_dont_blame_nrpe_custom => 1,
    nrpe_incdir_custom => "$nrpe_incdir",
  } ->
  class { "nagios::nrpe_incdir": } ->  # needed only on the client
  class { "nagios::client": } ->
  # Define hostgroups this host belongs to
  class { "nagios::host": hostgroups => "database-servers, file-servers, web-servers" }
  # NRPE commands need to be defined on the nagios client!
  nagios::command {"check_disk": command_name => "check_disk",
    command_line => "${nagios::user1}/check_disk -w \$ARG1\$ -c \$ARG2\$ -p \$ARG3\$ -X devtmpfs -X tmpfs -A -i /sys/fs/pstore -i /sys/kernel/config",
    exported_resource => false,
  }
  # Configuration for plugins available in the default installation, but commands undefined
  nagios::command {"check_pgsql": command_name => "check_pgsql",
    command_line => "${nagios::user1}/check_pgsql --logname nagios -H localhost -d template1",
    exported_resource => false,
  }
  #
  nagios::command {"check_tcp": command_name => "check_tcp",
    command_line => "${nagios::user1}/check_tcp -H \$ARG1\$ -p \$ARG2\$",
    exported_resource => false,
  }
  #
  nagios::command {"check_total_procs_custom": command_name => "check_total_procs_custom",
    command_line => "${nagios::user1}/check_procs -w \$ARG1\$ -c \$ARG2\$",
    exported_resource => false,
  }
  nagios::command {"check_ping_custom": command_name => "check_ping_custom",
    command_line => "${nagios::user1}/check_ping -H \$ARG1\$ -w 10,50% -c 50,75% -p 5",
    exported_resource => false,
  }
  #
  nagios::command {"check_ssh_custom": command_name => "check_ssh_custom",
    command_line => "${nagios::user1}/check_ssh -H \$ARG1\$",
    exported_resource => false,
  }
}

# Ubuntu nagios client
node "ubuntu14" {
  Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }
  class { "nagios": server_custom => $server,
    sysconfdir_custom => "$sysconfdir",
    user1_custom => "/usr/lib/nagios/plugins",  # PATH to plugins on Debian
    nrpe_dont_blame_nrpe_custom => 1,
    nrpe_incdir_custom => "$nrpe_incdir",
  } ->
  class { "nagios::nrpe_incdir": } ->  # needed only on the client
  class { "nagios::client": } ->
  # Define hostgroups this host belongs to
  class { "nagios::host": hostgroups => "database-servers" }
  # NRPE commands need to be defined on the nagios client!
  nagios::command {"check_disk": command_name => "check_disk",
    command_line => "${nagios::user1}/check_disk -w \$ARG1\$ -c \$ARG2\$ -p \$ARG3\$ -X devtmpfs -X tmpfs -A -i .gvfs",
    exported_resource => false,
  }
}

# FreeBSD nagios client
node "freebsd10" {
  Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }
  # https://github.com/puppetlabs/puppet/blob/master/lib/puppet/provider/package/ports.rb#L9
  Package { provider => $operatingsystem ? { freebsd => pkgng, }} # not yet in puppet 3.6.2_2
  class { "nagios": server_custom => $server,
    sysconfdir_custom => "$sysconfdir",
    user1_custom => "/usr/lib/nagios/plugins",  # PATH to plugins on FreeBSD
    nrpe_dont_blame_nrpe_custom => 1,
    nrpe_incdir_custom => "$nrpe_incdir",
    nrpe_pkg_custom => "net-mgmt/nrpe",
    nrpe_sysconfdir_custom => "/usr/local/etc",
    nrpe_servicename_custom => "nrpe2",
  } ->
  class { "nagios::nrpe_incdir": } ->  # needed only on the client
  class { "nagios::client": } ->
  # Define hostgroups this host belongs to
  class { "nagios::host": hostgroups => "batch-servers" }
}

# Nagios server
node "nagiosserver" {
  Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }
  class { "nagios": server_custom => $server,
    sysconfdir_custom => "$sysconfdir",
    nrpe_dont_blame_nrpe_custom => 1,
    nrpe_incdir_custom => "$nrpe_incdir",
  } ->
  class { "nagios::confdir": } ->
  class { "nagios::htpasswd_file": } ->
  class { "nagios::server": } 
  # contact groups defined on the nagios server only
  # no emails if "nagiosadmins" contactgroup is not defined
  nagios::contactgroup {"nagiosadmins": contactgroup_name => "nagiosadmins", alias => "Nagios administrators" }
  # contacts defined on the nagios server only
  nagios::contact {"admin1": contact_name => "admin1", alias => "admin1", contactgroups => "nagiosadmins", email => "admin1@com" }
  # general hostgroups defined on the nagios server only
  nagios::hostgroup {"batch-servers": hostgroup_name => "batch-servers", alias => "Batch servers" }
  nagios::hostgroup {"database-servers": hostgroup_name => "database-servers", alias => "Database servers" }
  nagios::hostgroup {"file-servers": hostgroup_name => "file-servers", alias => "File servers" }
  nagios::hostgroup {"web-servers": hostgroup_name => "web-servers", alias => "Web servers" }
  # general servicegroups defined on the nagios server only - used in the "Service Groups" web-interface
  # We are not using these, instead the service groups are
  # described verbosely, as e.g. "check_ping!50,10%!100,30%", using the alias keyword below
  nagios::servicegroup {"apache-services": servicegroup_name => "apache-services", alias => "Apache services" }
  nagios::servicegroup {"smb-services": servicegroup_name => "smb-services", alias => "Samba services" }
  nagios::servicegroup {"pgsql-services": servicegroup_name => "pgsql-services", alias => "PostgreSQL services" }
  #
  # general service defined on the nagios server only
  nagios::servicegroup {"check_ping": servicegroup_name => "check_ping",
    alias => "check_ping!50,10%!100,30%" }
  nagios::service {"check_ping": service_description => "check_ping",
    check_command => "check_ping!50,10%!100,30%",
    hostgroup_name => $nagios_hostgroup_all,  # ping hosts in all host groups
    servicegroups => "check_ping"}
  #
  nagios::servicegroup {"check_ssh": servicegroup_name => "check_ssh",
    alias => "check_ssh!-p 22" }
  nagios::service {"check_ssh": service_description => "check_ssh",
    check_command => "check_ssh!-p 22",
    hostgroup_name => $nagios_hostgroup_all,
    servicegroups => "check_ssh"}
  #
  # example of service dependency: check_ssh depends on check_ping
  nagios::servicedependency {"check_ssh_IF_check_ping":
    dependent_hostgroup_name => $nagios_hostgroup_all,
    dependent_service_description => "check_ssh",
    hostgroup_name => $nagios_hostgroup_all,
    service_description => "check_ping"}
  #
  nagios::servicegroup {"check_http": servicegroup_name => "check_http",
    alias => "check_http!-p 80" }
  nagios::service {"check_http": service_description => "check_http",
    check_command => "check_http!-p 80",
    hostgroup_name => "web-servers",  # check http on web servers only
    servicegroups => "check_http"}
  #
  nagios::servicegroup {"check_dns": servicegroup_name => "check_dns",
    alias => "check_dns!2!5" }
  nagios::service {"check_dns": service_description => "check_dns",
    check_command => "check_dns!2!5",
    hostgroup_name => $nagios_hostgroup_all,
    servicegroups => "check_dns"}
  # Debian/Ubuntu define this command in /etc/nagios-plugins/config/dns.cfg
  if $::osfamily != 'debian' {
    nagios::command {"check_dns": command_name => "check_dns",
      command_line => "${nagios::user1}/check_dns -H \$HOSTADDRESS\$ -w \$ARG1\$ -c \$ARG2\$",
      exported_resource => true,
    }
  }
  #
  nagios::servicegroup {"check_https_cert": servicegroup_name => "check_https_cert",
    alias => "check_http!--ssl!30" }
  nagios::service {"check_https_cert": service_description => "check_https_cert",
    check_command => "check_http!--ssl!30",
    hostgroup_name => "web-servers",
    servicegroups => "check_https_cert"}
  nagios::command {"check_https_cert": command_name => "check_https_cert",
    # use the line below if run on an HTTP server
    command_line => "${nagios::user1}/check_http -H \$HOSTADDRESS\$ \$ARG1\$ -C \$ARG2\$",
    exported_resource => true,
  }
  #
  # custom, downloaded plugins (non-NRPE, defined on the nagios server only)
  nagios::servicegroup {"check_smb": servicegroup_name => "check_smb",
    alias => "check_smb" }
  nagios::service {"check_smb": service_description => "check_smb",
    check_command => "check_smb",
    hostgroup_name => "file-servers",
    servicegroups => "check_smb"}
  nagios::command {"check_smb": command_name => "check_smb",
    command_line => "${nagios::user1}/check_smb.sh -H \$HOSTADDRESS\$",
    exported_resource => true,
    command_source => "check_smb.sh",
  }
  #
  # Debian/Ubuntu define this command in /etc/nagios-plugins/config/check_nrpe.cfg
  if $::osfamily != 'debian' {
    # check_nrpe_1arg/check_nrpe need to be defined on the server only
    nagios::command {"check_nrpe_1arg": command_name => "check_nrpe_1arg",
      command_line => "\$USER1$/check_nrpe -H \$HOSTADDRESS$ -c \$ARG1$" }
    nagios::command {"check_nrpe": command_name => "check_nrpe",
      command_line => "\$USER1$/check_nrpe -H \$HOSTADDRESS$ -c \$ARG1$ -a \$ARG2$" }
  }
  #
  # general nrpe checks need to be defined on the server only
  nagios::servicegroup {"nrpe_check_load": servicegroup_name => "nrpe_check_load",
    alias => "check_load" }
  nagios::service {"nrpe_check_load": service_description => "nrpe_check_load",
    check_command => "check_nrpe_1arg!check_load",
    hostgroup_name => "database-servers,file-servers,web-servers",
    servicegroups => "nrpe_check_load"}
  #
  nagios::servicegroup {"nrpe_check_total_procs": servicegroup_name => "nrpe_check_total_procs",
    alias => "check_total_procs" }
  nagios::service {"nrpe_check_total_procs": service_description => "nrpe_check_total_procs",
    check_command => "check_nrpe_1arg!check_total_procs",
    hostgroup_name => "database-servers,file-servers,web-servers",
    servicegroups => "nrpe_check_total_procs"}
  #
  nagios::servicegroup {"nrpe_check_pgsql": servicegroup_name => "nrpe_check_pgsql",
    alias => "check_pgsql" }
  nagios::service {"nrpe_check_pgsql": service_description => "nrpe_check_pgsql",
    check_command => "check_nrpe_1arg!check_pgsql",
    hostgroup_name => "database-servers",
    servicegroups => "nrpe_check_pgsql"}
  #
  # nrpe with user-supplied command
  nagios::servicegroup {"nrpe_check_total_procs_custom": servicegroup_name => "nrpe_check_total_procs_custom",
    alias => "check_total_procs_custom!750!1000" }
  nagios::service {"nrpe_check_total_procs_custom": service_description => "nrpe_check_total_procs_custom",
    check_command => "check_nrpe!check_total_procs_custom!750 1000",
    hostgroup_name => "database-servers",
    servicegroups => "nrpe_check_total_procs_custom"}
  #
  # nrpe checks that use check_disk
  nagios::servicegroup {"nrpe_check_disk_root": servicegroup_name => "nrpe_check_disk_root",
    alias => "check_disk!20% 10% /" }
  nagios::service {"nrpe_check_disk_root": service_description => "nrpe_check_disk_root",
    check_command => "check_nrpe!check_disk!20% 10% /",  # these are the two args to check_nrpe
    hostgroup_name => "database-servers,file-servers,web-servers",
    servicegroups => "nrpe_check_disk_root",
  }
  #
  # NRPE check for Torque batch system port
  nagios::servicegroup {"nrpe_check_tcp_torque_15001": servicegroup_name => "nrpe_check_tcp_torque_15001",
    alias => "check_tcp!localhost 15001" }
  nagios::service {"nrpe_check_tcp_torque_15001": service_description => "nrpe_check_tcp_torque_15001",
    check_command => "check_nrpe!check_tcp!localhost 15001",
    hostgroup_name => "batch-servers",
    servicegroups => "nrpe_check_tcp_torque_15001",
  }
}
