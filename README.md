-----------
Description
-----------

A puppet module that installs and configures Nagios server and clients.
Supported on Debian(Ubuntu), CentOS(Fedora) and FreeBSD (FreeBSD only as a client).

Tested on: Debian 7/8, Ubuntu 14.04, CentOS 6/7, Fedora 20, and FreeBSD 10.


------------
Sample Usage
------------

Assuming you have VirtualBox and Vagrant installed
https://www.virtualbox.org/ https://www.vagrantup.com/downloads.html
test the module with::

        $ git clone https://github.com/marcindulak/puppet-nagios.git
        $ cd puppet-nagios
        $ vagrant up
        $ vagrant ssh nagiosserver -c "sudo su -c 'service httpd start'"
        $ firefox http://localhost:8080/nagios  # credentials: nagiosadmin/nagiosadmin

You should see the following Nagios setup:

![Host Groups](https://raw.github.com/marcindulak/puppet-nagios/master/screenshots/hostgroups.png)
![Service Groups](https://raw.github.com/marcindulak/puppet-nagios/master/screenshots/servicegroups.png)

Test Nagios **check_http** plugin on the **nagiosserver**
command line against the **centos6** machine::

        $ vagrant ssh nagiosserver -c "sudo su -c '/usr/lib64/nagios/plugins/check_http -H centos6'"

Configure Apache on the **centos6** machine::

        $ vagrant ssh centos6 -c "sudo su -c 'yum install -y httpd'"
        $ vagrant ssh centos6 -c "sudo su -c 'touch /var/www/html/index.html'"
        $ vagrant ssh centos6 -c "sudo su -c 'chown apache.apache /var/www/html/index.html'"
        $ vagrant ssh centos6 -c "sudo su -c 'service httpd start'"

Test again::

        $ vagrant ssh nagiosserver -c "sudo su -c '/usr/lib64/nagios/plugins/check_http -H centos6'"

After a short time the service test corresponding to this plugin
should change status on the Nagios web interface.

Check NRPE **check_total_procs** plugin::

        $ vagrant ssh nagiosserver -c "sudo su -c '/usr/lib64/nagios/plugins/check_nrpe -H centos6 -c check_total_procs -a 150 200'"

When done, destroy the test machines with::

        $ vagrant destroy -f

All the steps performed by [Vagrantfile](Vagrantfile) are described below.


0. Install and configure puppet
-------------------------------

Skip to the next section if you have puppetmaster with puppetdb running.

This module uses puppetdb, not packaged yet for the targeted
operating systems (see e.g. https://bugzilla.redhat.com/show_bug.cgi?id=1068867).
Use the puppet packages provided by puppetlabs.com instead: for Ubuntu/Debian
install the deb package for your OS version from http://apt.puppetlabs.com/,
and for Fedora/CentOS install the RPM from http://yum.puppetlabs.com/.

Note that this module does not handle firewall settings, you are on your own.
Moreover puppetdb settings are IPv4-centric - disable IPv6 on the puppetmaster!

Install the puppetmaster server machine:

* on Debian/Ubuntu::

        $ sudo apt-get -y install puppetmaster puppetdb puppetdb-terminus

* on CentOS/Fedora::

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

* on CentOS/Fedora (on CentOS enable the EPEL repository https://fedoraproject.org/wiki/EPEL)::

        $ su -c "yum -y install puppet"

* on FreeBSD, as root, switch to pkgng first::

        # env ASSUME_ALWAYS_YES=YES pkg bootstrap
        # pkg2ng

  then install/configure puppet and the **pkgng** puppet provider::

        # pkg install -y puppet git
        # cp /usr/local/etc/puppet/puppet.conf-dist /usr/local/etc/puppet/puppet.conf
        # sed -i '' '/.*isc\.freebsd\.org.*/d' /usr/local/etc/puppet/puppet.conf
        # echo 'puppet_enable="YES"' >> /etc/rc.conf

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

* on CentOS/Fedora (on CentOS enable the EPEL repository https://fedoraproject.org/wiki/EPEL)::

        $ su -c "yum -y install git"
        $ cd /etc/puppet/modules
        $ su -c "mkdir -p ../manifests"
        $ su -c "git clone https://github.com/marcindulak/puppet-nagios.git"
        $ su -c "ln -s puppet-nagios nagios"


2. Configure the module:
------------------------

On the puppetmaster server, as root user, create the /etc/puppet/manifests/site.pp file.

Use the [example site.pp](tests/site.pp) file.

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

In order to access the Nagios web interface, on the Nagios server (on CentOS)::

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

* on CentOS/Fedora:

        $ su -c "puppet apply --verbose /etc/puppet/manifests/site.pp"


------------
Dependencies
------------

pkgng provider on FreeBSD. Install it on puppetmaster as described at
https://forge.puppetlabs.com/zleslie/pkgng


----
Todo
----

