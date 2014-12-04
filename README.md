-----------
Description
-----------

A puppet module that installs and configures Nagios server and clients.
Supported on Debian(Ubuntu), RHEL(Fedora) and FreeBSD (FreeBSD only as a client).

Tested on: Debian 7/8, Ubuntu 14.04, RHEL 6/7, Fedora 20, and FreeBSD 10.1.

------------
Sample Usage
------------

0. Install and configure puppet
-------------------------------

Skip to the next section if you have puppetmaster with puppetdb running.

This module uses puppetdb, not packaged yet for the targeted
operating systems (see e.g. https://bugzilla.redhat.com/show_bug.cgi?id=1068867).
Use the puppet packages provided by puppetlabs.com instead: for Ubuntu/Debian
install the deb package for your OS version from http://apt.puppetlabs.com/,
and for Fedora/RHEL install the RPM from http://yum.puppetlabs.com/.

Note that this module does not handle firewall settings, you are on your own.
Moreover puppetdb settings are IPv4-centric - disable IPv6 on the puppetmaster!

Install the puppetmaster server machine:

* on Debian/Ubuntu::

        $ sudo apt-get -y install puppetmaster puppetdb puppetdb-terminus

* on RHEL/Fedora::

        $ su -c "yum -y install puppet-server puppetdb puppetdb-terminus"

Configure puppetdb on the puppetmaster server:

- the built-in HSQLDB database is configured by default for puppetdb.
  https://docs.puppetlabs.com/puppetdb/latest/configure.html#database-settings
  You should consider using PostresSQL in a production environment.

- perform additional configuration steps::

        cat <<END > /etc/puppet/puppetdb.conf
        [main]
        server = `hostname`
        port = 8081
        END

        cat <<END >> /etc/puppet/puppet.conf
        [master]
        storeconfigs = true
        storeconfigs_backend = puppetdb
        reports = store,puppetdb
        END

  and::

```lang
        cat <<END > /etc/puppet/routes.yaml
        master:
	       facts:
	         terminus: puppetdb
	         cache: yaml
        END
```

- start (it may take a minute) and enable puppetdb::

        systemctl start puppetmaster.service  # service puppetmaster start
        puppetdb ssl-setup
        systemctl start puppetdb.service  # service puppetdb start
        systemctl enable puppetdb.service  # chkconfig puppetdb on
        systemctl restart puppetmaster.service  # service puppetmaster restart
        systemctl enable puppetmaster.service  # chkconfig puppetmaster on

  and verify that the ports are open::

        netstat -ntlp | grep -E '8080|8081|8140'

On the puppet agent client machines there is no need for using
the packages from puppetlabs.com, use the distribution packages instead:

* on Debian/Ubuntu::

        $ sudo apt-get -y install puppet

* on RHEL/Fedora (on RHEL enable the EPEL repository https://fedoraproject.org/wiki/EPEL)::

        $ su -c "yum -y install puppet"

* on FreeBSD, as root, switch to pkgng first::

        # env ASSUME_ALWAYS_YES=YES pkg bootstrap
        # pkg2ng

  then install/configure puppet and the **pkgng** puppet provider::

        # pkg install -y puppet git
        # cp /usr/local/etc/puppet/puppet.conf-dist /usr/local/etc/puppet/puppet.conf
        # echo 'puppet_enable="YES"' >> /etc/rc.conf
        # cd /usr/local/etc/puppet/modules
        # git clone https://github.com/xaque208/puppet-pkgng.git pkgng

  Note: to use NRPE on FreeBSD the Nagios NRPE must be compiled with SSL support (from /usr/ports).

Make sure that the puppet agent configuration file `puppet.conf`
on all the clients contains the hostname of your puppetmaster server::

       [agent]
       server = puppetmaster.com

On the client (e.g. nagiosserver.com) generate the certificate signing request by running::

       puppet agent -t

and accept the certificate on the puppetmaster server::

       puppet cert list
       puppet cert sign nagiosserver.com

Perform these steps on all your puppet clients.
If you run into MD5/SHA256 certificate issues
https://tickets.puppetlabs.com/browse/PUP-2992 - clean those certificates
on the puppetmaster, and use the puppet from the puppetlabs repositories
on the clients to create new certificates.

1. Install the module and dependencies
--------------------------------------

On the puppetmaster server (only) install the puppet-nagios module:

* on Debian/Ubuntu::

        $ sudo apt-get -y install git
        $ cd /etc/puppet/modules
        $ sudo mkdir -p ../manifests
        $ sudo git clone https://github.com/marcindulak/puppet-nagios.git
        $ sudo ln -s puppet-nagios nagios

* on RHEL/Fedora (on RHEL enable the EPEL repository https://fedoraproject.org/wiki/EPEL)::

        $ su -c "yum -y install git"
        $ cd /etc/puppet/modules
        $ su -c "mkdir -p ../manifests"
        $ su -c "git clone https://github.com/marcindulak/puppet-nagios.git"
        $ su -c "ln -s puppet-nagios nagios"


2. Configure the module:
------------------------

On the puppetmaster server, as root user, create the /etc/puppet/manifests/site.pp file.

The settings below should result in the following Nagios (RHEL as the server) configuration:

![Host Groups](https://raw.github.com/marcindulak/puppet-nagios/master/screenshots/hostgroups.png)
![Service Groups](https://raw.github.com/marcindulak/puppet-nagios/master/screenshots/servicegroups.png)

	# nagios server
	$server = "nagiosserver.com"
	# nagios configuration directory must be consistent across exported resources
	#$sysconfdir = "/etc/nagios3"  # Debian/Ubuntu
	$sysconfdir = "/etc/nagios"  # RHEL/Fedora
	#$sysconfdir = "/usr/local/etc/nagios"  # FreeBSD
	# RHEL SELinux blocks NRPE in directories other than /etc/nrpe.d
	$nrpe_incdir = "/etc/nrpe.d"

	# all hosts groups: group hosts by their purpose
	$nagios_hostgroup_all = "batch-servers, database-servers, file-servers, web-servers"

	# RHEL6 (32-bit) nagios client
	node "RHEL6.com" {
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
	node "RHEL7.com" {
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
	node "Ubuntu14.04.com" {
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
	node "FreeBSD10.1.com" {
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
	node "nagiosserver.com" {
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


Change permissions so only root can read your configuration and credentials (if any)::

    # chmod go-rwx /etc/puppet/manifests/site.pp


3. Apply the module:
--------------------

Apply the module on the Nagios server and clients::

        puppet agent -t

If no Nagios client is known to the Nagios server the puppet agent run on
the Nagios server will fail at starting the Nagios service.
Due to the way the flat configuration files needed by Nagios are
created on the Nagios server and clients by puppet you may need
to run puppet agent twice.

In order to access the Nagios web interface, on the Nagios server (on RHEL)::

        systemctl start httpd.service  # service httpd start
        systemctl enable httpd.service  # chkconfig httpd on

and access `firefox http://localhost/nagios` (http://localhost/nagios3 on Debian/Ubuntu)
with the default credentials `nagiosadmin`: `nagiosadmin`.
On Debian/Ubuntu the Nagios user needs to be created with::

         sudo htpasswd -c /etc/nagios3/htpasswd.users nagiosadmin

In case of problems there is a good troubleshooting guide at
http://assets.nagios.com/downloads/nagiosxi/docs/NRPE-Troubleshooting-and-Common-Solutions.pdf

Note that Nagios installation on Debian/Ubuntu is missing some
basic definitions like `generic-host`, `generic-contact`, etc.
Fix this by manually doing (one time operation)::

        $ sudo mkdir -p /etc/nagios3/objects
        $ sudo cp -p /usr/share/doc/nagios3-common/examples/template-object/*.cfg /etc/nagios3/objects
        $ sudo cp -p /usr/share/doc/nagios3-common/examples/template-object/templates.cfg.gz /etc/nagios3/objects
        $ cd /etc/nagios3/objects
        $ sudo gunzip templates.cfg.gz
        $ sudo chown nagios:nagios /etc/nagios3/objects

uncomment the corresponding files in `/etc/nagios3/nagios.cfg`
and rerun puppet agent on the Nagios server.

The command below is used only for standalone runs
(without puppetmaster, in case the Nagios server is on the same host as the client)::

* on Debian/Ubuntu:

        $ sudo puppet apply --verbose --debug /etc/puppet/manifests/site.pp

* on RHEL/Fedora:

        $ su -c "puppet apply --verbose /etc/puppet/manifests/site.pp"


------------
Dependencies
------------

pkgng provider on FreeBSD.

----
Todo
----
