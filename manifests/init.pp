class nagios (
  $basename_custom = undef,  # e.g. nagios
  $server_pkg_custom = undef,  # e.g. nagios
  $servicename_custom = undef,  # e.g. nagios
  $sysconfdir_custom = undef,  # e.g. /etc/nagios
  $confdir_custom = undef,  # e.g. /etc/nagios/conf.d
  $htpasswd_file_custom = undef,  # e.g. /etc/nagios/passwd
  $nagios_group_custom = undef,  # e.g. nagios
  $apache_group_custom = undef,  # e.g. www
  $server_custom = undef,  # e.g. nagios01 - server name or IP
  $plugins_pkg_custom = undef,  # e.g. nagios-plugins-all
  $user1_custom = undef,  # e.g. /usr/lib64/nagios/plugins
  $nrpe_sysconfdir_custom = undef,  # e.g. /etc/nagios
  $plugins_nrpe_pkg_custom = undef,  # e.g. nagios-plugins-nrpe
  $nrpe_pkg_custom = undef,  # e.g. nrpe
  $nrpe_servicename_custom = undef,  # e.g. nrpe
  $nrpe_dont_blame_nrpe_custom = undef,  # {0,1}
  $nrpe_incdir_custom = undef,  # e.g. RedHat /etc/nrpe.d Debian /etc/nagios/nrpe.d
  #
  $nrpe_group_custom = undef,  # e.g. nrpe - needed, e.g by apache
  ) {
    
    #notify { "inside nagios $nagios $::osfamily $::operatingsystem": }
    
    # nagios directory structure name
    $basename = $basename_custom ? {
      undef => $::osfamily ? {
        'Debian' => 'nagios3',
        'RedHat' => 'nagios',
        'FreeBSD' => 'nagios',
      },
    default => $basename_custom,
    }
    
    # nagios package name
    $server_pkg = $server_pkg_custom ? {
      undef => "$nagios::basename",
      default => $server_pkg_custom,
    }

    # nagios service name
    $servicename = $servicename_custom ? {
      undef => "$nagios::basename",
      default => $servicename_custom,
    }
    
    # nagios sysconf directory
    $sysconfdir = $sysconfdir_custom ? {
      undef => "/etc/$nagios::basename" ,
      default => $sysconfdir_custom,
    }
    
    # nagios conf directory
    $confdir = $confdir_custom ? {
      undef => "$nagios::sysconfdir/conf.d" ,
      default => $confdir_custom,
    }
    
    # nagios htpasswd file
    $htpasswd_file = $htpasswd_file_custom ? {
      undef => $::osfamily ? {
        'Debian' => "$nagios::sysconfdir/htpasswd.users",
        'RedHat' => "$nagios::sysconfdir/passwd",
        'FreeBSD' => "$nagios::sysconfdir/htpasswd.users",
      },
    default => $htpasswd_file_custom,
    }
    
    # nagios UNIX group
    $nagios_group = $nagios_group_custom ? {
      undef => $::osfamily ? {
        'Debian' => 'nagios',
        'RedHat' => 'nagios',
        'FreeBSD' => 'nagios',
      },
    default => $nagios_group_custom,
    }

    # apache UNIX group
    $apache_group = $apache_group_custom ? {
      undef => $::osfamily ? {
        'Debian' => 'www-data',
        'RedHat' => 'apache',
        'FreeBSD' => 'www',
      },
    default => $apache_group_custom,
    }
    
    # nagios server name or IP
    $server = $server_custom ? {
      undef => "localhost" ,
      default => $server_custom,
    }
    
    # plugins packages
    $plugins_pkg = $plugins_pkg_custom ? {
      undef => $::osfamily ? {
        'Debian' => "nagios-plugins",
        'RedHat' => "nagios-plugins-all",
        'FreeBSD' => "net-mgmt/nagios-plugins",
      },
    default => $plugins_pkg_custom,
    }
    
    # nrpe sysconf directory
    $nrpe_sysconfdir = $nrpe_sysconfdir_custom ? {
      undef => "$nagios::sysconfdir" ,
      default => $nrpe_sysconfdir_custom,
    }
    
    # plugins nrpe packages
    $plugins_nrpe_pkg = $plugins_nrpe_pkg_custom ? {
      undef => $::osfamily ? {
        'Debian' => "nagios-nrpe-plugin",
        'RedHat' => "nagios-plugins-nrpe",
        'FreeBSD' => "net-mgmt/nrpe",
      },
    default => $plugins_nrpe_pkg_custom,
    }
    
    # nrpe server package
    $nrpe_pkg = $nrpe_pkg_custom ? {
      undef => $::osfamily ? {
        'Debian' => "nagios-nrpe-server",
        'RedHat' => "nrpe",
        'FreeBSD' => "nrpe",
      },
    default => $nrpe_pkg_custom,
    }

    # nrpe $USER1$ package
    $user1 = $user1_custom ? {
      undef => $::osfamily ? {
        'Debian' => $::architecture ? {
          'amd64' => "/usr/lib/nagios/plugins",
          'i386'   => "/usr/lib/nagios/plugins",},
        'RedHat' => $::architecture ? {
          'x86_64' => "/usr/lib64/nagios/plugins",
          'i386'   => "/usr/lib/nagios/plugins",},
        'FreeBSD' => "/usr/local/libexec/nagios",
      },
      default => $user1_custom,
    }

    # nrpe service name
    $nrpe_servicename = $nrpe_servicename_custom ? {
      undef => $::osfamily ? {
        'Debian' => "nagios-nrpe-server",
        'RedHat' => "nrpe",
        'FreeBSD' => "nrpe2",
      },
    default => $nrpe_servicename_custom,
    }

    # dont_blame_nrpe
    $nrpe_dont_blame_nrpe = $nrpe_dont_blame_nrpe_custom ? {
      undef => 0,
      default => $nrpe_dont_blame_nrpe_custom,
    }
    
    # nrpe include directory
    $nrpe_incdir = $nrpe_incdir_custom ? {
      undef => $::osfamily ? {
        'Debian' => "$nagios::nrpe_sysconfdir/nrpe.d",
        'RedHat' => "/etc/nrpe.d",
        'FreeBSD' => "$nagios::nrpe_sysconfdir/nrpe.d",  # MDTMP - is it right?
      },
    default => $nrpe_incdir_custom,
    }
    
    # nrpe UNIX group (needed e.g. for apache)
    $nrpe_group = $nrpe_group_custom ? {
      undef => $::osfamily ? {
        'Debian' => 'nrpe',
        'RedHat' => 'nrpe',
        'FreeBSD' => 'nrpe',
      },
    default => $default,
    }
  }

class nagios::confdir {

  # Avoid duplicate resources https://groups.google.com/forum/#!topic/puppet-users/uNHIV-Uj4yI
  if ! defined(Package[ "$nagios::server_pkg" ]) {
    package { "$nagios::server_pkg": ensure => installed; }
  }
  
  group { "$nagios::nagios_group":
    ensure => present,
  }
  
  #notify { "inside nagios $nagios::confdir": }
  
  file { "$nagios::confdir":
    path   => "$nagios::confdir",
    ensure => directory,
    owner => "root",
    group => "$nagios::nagios_group",
    mode => 770,  # permissions of /etc/nagios/conf.d on el6
    # http://christian.hofstaedtler.name/blog/2008/11/puppet-managing-directories-recursively.html
    purge => true, # purge all unmanaged junk - all un-nagiosed hosts cfg files
    # must be recursive to purge!
    recurse => true, # enable recursive directory management
    # purge seems to remove the contents every time!
    require => Package["$nagios::server_pkg"],
    notify => Service["$nagios::servicename"],
  }
}

class nagios::nrpe_incdir {

  # Avoid duplicate resources https://groups.google.com/forum/#!topic/puppet-users/uNHIV-Uj4yI
  if ! defined(Package[ "$nagios::nrpe_pkg" ]) {
    package { "$nagios::nrpe_pkg": ensure => installed; }
  }

  group { "$nagios::nrpe_group":
    ensure => present,
  }
  
  #notify { "inside nagios $nagios::nrpe_incdir": }
  
  file { "$nagios::nrpe_incdir":
    path   => "$nagios::nrpe_incdir",
    ensure => directory,
    owner => "root",
    group => "$nagios::nrpe_group",
    mode => 770,  # permissions of /etc/nagios/conf.d on el6
    # http://christian.hofstaedtler.name/blog/2008/11/puppet-managing-directories-recursively.html
    purge => true, # purge all unmanaged junk - all un-nagiosed hosts cfg files
    # must be recursive to purge!
    recurse => true, # enable recursive directory management
    # purge seems to remove the contents every time!
    require => Package["$nagios::nrpe_pkg"],
    notify => Service["$nagios::nrpe_servicename"],
  }
}

class nagios::htpasswd_file {

  if ! defined(Package[ "$nagios::server_pkg" ]) {
    package { "$nagios::server_pkg": ensure => installed; }
  }

  #notify { "inside nagios $nagios::htpasswd_file": }

  file { "$nagios::htpasswd_file":
    path   => "$nagios::htpasswd_file",
    ensure => file,
    owner => "root",
    group => "$nagios::apache_group",
    mode => 660,
    require => Package["$nagios::server_pkg"],
    notify => Service["$nagios::servicename"],
  }
}

class nagios::server {

  if ! defined(Package[ "$nagios::server_pkg" ]) {
    package { "$nagios::server_pkg": ensure => installed; }
  }
  if ! defined(Package[ "$nagios::plugins_pkg" ]) {
    package { "$nagios::plugins_pkg": ensure => installed; }
  }
  # check_nrpe needed on the Nagios server, otherwise
  # (Return code of 127 is out of bounds - plugin may be missing)
  if ! defined(Package[ "$nagios::plugins_nrpe_pkg" ]) {
    package { "$nagios::plugins_nrpe_pkg": ensure => installed; }
  }
  
  service { "$nagios::servicename":
    ensure => running,
    enable => true,
    # Work around files created root:root mode 600 (known issue)
    # http://projects.puppetlabs.com/issues/3299
    # From https://raw.github.com/thias/puppet-nagios/master/manifests/server.pp
    start => "find $nagios::confdir -type f -name '*.cfg' | xargs -r -I f sh -c 'chgrp $nagios::nagios_group f; chmod g+r f'&& service $nagios::servicename start",
    restart => "find $nagios::confdir -type f -name '*.cfg' | xargs -r -I f sh -c 'chgrp $nagios::nagios_group f; chmod g+r f'&& service $nagios::servicename restart",
    require => Package["$nagios::server_pkg"],
  }

  # cfg_dir not configured on FreeBSD
  exec { "$nagios::sysconfdir/nagios.cfg_confdir":
    command => "echo 'cfg_dir=$nagios::confdir' >> $nagios::sysconfdir/nagios.cfg",
    unless => "grep -E '^cfg_dir=$nagios::confdir' $nagios::sysconfdir/nagios.cfg",
    require => Package["$nagios::server_pkg"],
    notify => Service["$nagios::servicename"],
  }

  # Collect the nagios_contact resources
  Nagios_contact <<||>> {
    require => [File["$nagios::confdir"]],
    notify  => [Service["$nagios::servicename"]],
  }
  # Collect the nagios_contactgroup resources
  Nagios_contactgroup <<||>> {
    require => [File["$nagios::confdir"]],
    notify  => [Service["$nagios::servicename"]],
  }
  # Collect the nagios_host resources
  Nagios_host <<||>> {
    require => [File["$nagios::confdir"]],
    notify  => [Service["$nagios::servicename"]],
  }
  # Collect the nagios_hostgroup resources
  Nagios_hostgroup <<||>> {
    require => [File["$nagios::confdir"]],
    notify  => [Service["$nagios::servicename"]],
  }
  # Collect the nagios_service resources
  Nagios_service <<||>> {
    require => [File["$nagios::confdir"]],
    notify  => [Service["$nagios::servicename"]],
  }
  # Collect the nagios_servicedependency resources
  Nagios_servicedependency <<||>> {
    require => [File["$nagios::confdir"]],
    notify  => [Service["$nagios::servicename"]],
  }
  # Collect the nagios_service resources
  Nagios_servicegroup <<||>> {
    require => [File["$nagios::confdir"]],
    notify  => [Service["$nagios::servicename"]],
  }
  # Collect the nagios_command resources
  Nagios_command <<||>> {
    require => [File["$nagios::confdir"]],
    notify  => [Service["$nagios::servicename"]],
  }  
}

class nagios::client {

  # NRPE daemon needed on the Nagios client
  if ! defined(Package[ "$nagios::nrpe_pkg" ]) {
    package { "$nagios::nrpe_pkg": ensure => installed; }
  }
  if ! defined(Package[ "$nagios::plugins_pkg" ]) {
      package { "$nagios::plugins_pkg": ensure => installed; }
  }

  exec { "$nagios::nrpe_sysconfdir/nrpe.cfg_allowed_hosts":
    command => "sed -i -e 's|^allowed_hosts=.*|allowed_hosts=127.0.0.1,$nagios::server|g' $nagios::nrpe_sysconfdir/nrpe.cfg",
    onlyif => "grep -E '^allowed_hosts=.*' $nagios::nrpe_sysconfdir/nrpe.cfg",
    require => Package["$nagios::nrpe_pkg"],
    notify => Service["$nagios::nrpe_servicename"],
  }
  exec { "$nagios::nrpe_sysconfdir/nrpe.cfg_nrpe_dont_blame_nrpe":
    command => "sed -i -e 's|^dont_blame_nrpe=.*|dont_blame_nrpe=$nagios::nrpe_dont_blame_nrpe|g' $nagios::nrpe_sysconfdir/nrpe.cfg",
    onlyif => "grep -E '^dont_blame_nrpe=.*' $nagios::nrpe_sysconfdir/nrpe.cfg",
    require => Package["$nagios::nrpe_pkg"],
    notify => Service["$nagios::nrpe_servicename"],
  }
  exec { "$nagios::nrpe_sysconfdir/nrpe.cfg_incdir":
    command => "sed -i -e 's|^#include_dir=<somedirectory>|include_dir=$nagios::nrpe_incdir|g' $nagios::nrpe_sysconfdir/nrpe.cfg",
    onlyif => "grep -E '^#include_dir=<somedirectory>' $nagios::nrpe_sysconfdir/nrpe.cfg",
    require => Package["$nagios::nrpe_pkg"],
    notify => Service["$nagios::nrpe_servicename"],
  }

  service { "$nagios::nrpe_servicename":
    ensure => running,
    enable => true,
    start => "find $nagios::nrpe_incdir 2>/dev/null&& find $nagios::nrpe_incdir -type f -name '*.cfg' | xargs -r -I f sh -c 'chgrp $nagios::nrpe_group f; chmod g+r f'&& service $nagios::nrpe_servicename start",
    restart => "find $nagios::nrpe_incdir 2>/dev/null&& find $nagios::nrpe_incdir -type f -name '*.cfg' | xargs -r -I f sh -c 'chgrp $nagios::nrpe_group f; chmod g+r f'&& service $nagios::nrpe_servicename restart",
    require => Package["$nagios::nrpe_pkg"],
  }
}

define nagios::contact (
  $contact_name = undef,
  $alias = undef,
  $contactgroups = undef,
  $email = undef,
  ) {

    # from http://docs.puppetlabs.com/guides/exported_resources.html
    # there is --PUPPET_NAME-- bug http://projects.puppetlabs.com/issues/3420
    # or not http://projects.puppetlabs.com/issues/3498 ?
    @@nagios_contact { "${contact_name}":
      alias => $alias ? { undef => undef, default => $alias },
      contactgroups => $contactgroups ? { undef => 'admins', default => $contactgroups },
      email => $email,
      use => 'generic-contact',
      target => "$nagios::confdir/contact_${contact_name}.cfg",
    }    
}

define nagios::contactgroup (
  $contactgroup_name = undef,
  $alias = undef,
  ) {
    
    # Virtual definition that will become real on the server
    #notify { "inside nagios contactgroup class": }
    @@nagios_contactgroup { "$contactgroup_name":
      # http://docs.puppetlabs.com/learning/variables.html#selectors
      alias => $alias ? { undef => $contactgroup_name, default => $alias },
      target => "$nagios::confdir/contactgroup_${contactgroup_name}.cfg",
    }
  }

define nagios::hostgroup (
  $hostgroup_name = undef,
  $alias = undef,
  ) {
    
    # Virtual definition that will become real on the server
    #notify { "inside nagios hostgroup class": }
    @@nagios_hostgroup { "$hostgroup_name":
      # http://docs.puppetlabs.com/learning/variables.html#selectors
      alias => $alias ? { undef => $hostgroup_name, default => $alias },
      target => "$nagios::confdir/hostgroup_${hostgroup_name}.cfg",
    }
  }

define nagios::service (
  $service_description = undef,
  $check_command = undef,
  $check_interval = undef,
  $notification_interval = undef,
  $contact_groups = undef,
  $host_name = undef,
  $hostgroup_name = undef,
  $servicegroups = undef,
  ) {

    # from http://docs.puppetlabs.com/guides/exported_resources.html
    # there is --PUPPET_NAME-- bug http://projects.puppetlabs.com/issues/3420
    # or not http://projects.puppetlabs.com/issues/3498 ?
    @@nagios_service { "${service_description}":
      check_command => "$check_command",
      contact_groups => $contact_groups ? { undef => 'admins', default => $contact_groups },
      use => "generic-service",
      # http://docs.puppetlabs.com/learning/variables.html#selectors
      hostgroup_name => $hostgroup_name ? { undef => undef, default => $hostgroup_name },
      host_name => $host_name ? { undef => undef, default => $host_name },
      check_interval => $check_interval ? { undef => "1", default => $check_interval },
      notification_interval => $notification_interval ? { undef => "1", default => $notification_interval },
      service_description => "$service_description",
      target => "$nagios::confdir/service_${service_description}.cfg",
    }
    
    # if servicegroups defined - add it to the nagios_service
    if $servicegroups {
      nagios_service["${service_description}"] {
        servicegroups => "$servicegroups",
      }
    }
}

define nagios::servicedependency (
  $dependent_hostgroup_name = undef,
  $dependent_service_description = undef,
  $hostgroup_name = undef,
  $service_description = undef,
  $execution_failure_criteria = undef,
  $notification_failure_criteria = undef,
  ) {

    # from http://docs.puppetlabs.com/guides/exported_resources.html
    # there is --PUPPET_NAME-- bug http://projects.puppetlabs.com/issues/3420
    # or not http://projects.puppetlabs.com/issues/3498 ?
    @@nagios_servicedependency { "${dependent_service_description}_ON_${service_description}":
      dependent_hostgroup_name => $dependent_hostgroup_name,
      dependent_service_description => $dependent_service_description,
      hostgroup_name => $hostgroup_name,
      service_description => $service_description,
      execution_failure_criteria => $execution_failure_criteria ? { undef => 'w,u,c,p', default => $execution_failure_criteria },
      notification_failure_criteria => $notification_failure_criteria ? { undef => 'w,u,c', default => $notification_failure_criteria },
      target => "$nagios::confdir/servicedependency_${dependent_service_description}_ON_${service_description}.cfg",
    }    
}

define nagios::servicegroup (
  $servicegroup_name = undef,
  $alias = undef,
  ) {
    
    # Virtual definition that will become real on the server
    #notify { "inside nagios servicegroup class": }
    @@nagios_servicegroup { "$servicegroup_name":
      # http://docs.puppetlabs.com/learning/variables.html#selectors
      alias => $alias ? { undef => $servicegroup_name, default => $alias },
      target => "$nagios::confdir/servicegroup_${servicegroup_name}.cfg",
    }
  }

define nagios::command (
  $command_name = undef,
  $command_line = undef,
  $exported_resource = true,  # false creates a file on the node (used in custom nrpe checks)
  $command_source = undef,
  ) {
    
    # this is a nagios command to be defined under $nagios::nrpe_incdir on the given node
    if $exported_resource == true
    {
      # Virtual definition that will become real on the server
      #notify { "inside nagios command class": }
      @@nagios_command { "$command_name":
        # a good idea to define check_nrpe_1arg and check_nrpe
        # http://lowendbox.com/blog/remote-server-monitoring-with-nagios-centos/
        # http://docs.puppetlabs.com/learning/variables.html#selectors
        alias => $alias ? { undef => $command_name, default => $alias },
        command_line => "$command_line",
        target => "$nagios::confdir/command_${command_name}.cfg",
      }
      if $command_source {
        file { "$nagios::user1/${command_source}":
          ensure  => file,
          owner => "root",
          group => "$nagios::nagios_group",
          mode => 550,
          source => "puppet:///modules/nagios/$command_source",
          require => Package["$nagios::server_pkg"],
          notify => Service["$nagios::servicename"],
        }
      }
    }
    else
    {
      file { "$nagios::nrpe_incdir/command_${command_name}.cfg":
        ensure  => file,
        owner => "root",
        group => "$nagios::nrpe_group",
        mode => 660,
        content => "command[$command_name]=$command_line",
        require => Package["$nagios::nrpe_pkg"],
        notify => Service["$nagios::nrpe_servicename"],
      }
      if $command_source {
        file { "$nagios::user1/${command_source}":
          ensure  => file,
          owner => "root",
          group => "$nagios::nrpe_group",
          mode => 550,
          source => "puppet:///modules/nagios/$command_source",
          require => Package["$nagios::nrpe_pkg"],
          notify => Service["$nagios::nrpe_servicename"],
        }
      }
    }
  }

class nagios::host (
  $hostgroups = undef,
  $check_interval = undef,
  $notification_interval = undef,
  $contact_groups = undef,
  $interface = undef,
  ) {

    # Virtual definition that will become real on the server
    #notify { "inside nagios host class": }
    @@nagios_host { "$fqdn":
      ensure => present,
      alias => $hostname,
      address => $interface ? { "eth1" => $ipaddress_eth1, "em1" => $ipaddress_em1, "enp0s8" => $ipaddress_enp0s8, undef => $ipaddress, default => $ipaddress},
      contact_groups => $contact_groups ? { undef => 'admins', default => $contact_groups },
      use => "generic-host",
      max_check_attempts => "5",  # nagios fails to start without it on el6
      check_interval => $check_interval ? { undef => "1", default => $check_interval },
      notification_interval => $notification_interval ? { undef => "1", default => $notification_interval },
      # host must have a command defined
      # otherwise it sits with PENDING
      # http://forums.meulie.net/viewtopic.php?t=1201
      check_command => "check-host-alive",
      target => "$nagios::confdir/host_${fqdn}.cfg",
      # watch http://projects.puppetlabs.com/issues/3299
      #owner => "root",
      #group => "$nagios::group",
      #mode => 660;
      hostgroups => "$hostgroups",
    }
    }
