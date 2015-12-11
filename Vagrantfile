# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure(2) do |config|
  # puppet
  config.vm.define "puppet" do |puppet|
    puppet.vm.box = "puppetlabs/centos-6.6-64-nocm"
    puppet.vm.box_url = 'puppetlabs/centos-6.6-64-nocm'
    puppet.vm.synced_folder ".", "/etc/puppet/modules/nagios"
    puppet.vm.synced_folder "tests", "/etc/puppet/manifests"
    puppet.vm.network "private_network", ip: "192.168.0.4"
    puppet.vm.provider "virtualbox" do |v|
      v.memory = 256  # puppetdb is greedy
      v.cpus = 1
    end
  end
  # centos6 (32-bit) nagios client
  config.vm.define "centos6" do |centos6|
    centos6.vm.box = "puppetlabs/centos-6.6-32-nocm"
    centos6.vm.box_url = 'puppetlabs/centos-6.6-32-nocm'
    centos6.vm.network "private_network", ip: "192.168.0.10"
    centos6.vm.provider "virtualbox" do |v|
      v.memory = 128
      v.cpus = 1
    end
  end
  # centos7 nagios client
  config.vm.define "centos7" do |centos7|
    centos7.vm.box = "puppetlabs/centos-7.0-64-nocm"
    centos7.vm.box_url = 'puppetlabs/centos-7.0-64-nocm'
    centos7.vm.network "private_network", ip: "192.168.0.20"
    centos7.vm.provider "virtualbox" do |v|
      v.memory = 128
      v.cpus = 1
    end
  end
  # ubuntu nagios client
  config.vm.define "ubuntu14" do |ubuntu14|
    ubuntu14.vm.box = "puppetlabs/ubuntu-14.04-64-nocm"
    ubuntu14.vm.box_url = 'puppetlabs/ubuntu-14.04-64-nocm'
    ubuntu14.vm.network "private_network", ip: "192.168.0.30"
    ubuntu14.vm.synced_folder ".", "/vagrant", disabled: true
    ubuntu14.vm.provider "virtualbox" do |v|
      v.memory = 256  # Ubuntu is greedy
      v.cpus = 1
    end
  end
  # freebsd nagios client
  config.vm.define "freebsd10" do |freebsd10|
    freebsd10.vm.box = "bento/freebsd-10.2"
    freebsd10.vm.box_url = 'bento/freebsd-10.2'
    freebsd10.vm.network "private_network", ip: "192.168.0.40"
    freebsd10.vm.synced_folder ".", "/vagrant", disabled: true
    freebsd10.vm.provider "virtualbox" do |v|
      v.memory = 512  # FreeBSD is greedy
      v.cpus = 1
    end
  end
  # nagiosserver
  config.vm.define "nagiosserver" do |nagiosserver|
    nagiosserver.vm.box = "puppetlabs/centos-6.6-64-nocm"
    nagiosserver.vm.box_url = 'puppetlabs/centos-6.6-64-nocm'
    nagiosserver.vm.network "private_network", ip: "192.168.0.5"
    nagiosserver.vm.network "forwarded_port", guest: 80, host: 8080
    nagiosserver.vm.provider "virtualbox" do |v|
      v.memory = 128
      v.cpus = 1
    end
  end
  # disable IPv6 on Linux
  $linux_disable_ipv6 = <<SCRIPT
sysctl -w net.ipv6.conf.default.disable_ipv6=1
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.lo.disable_ipv6=1
SCRIPT
  # stop iptables
  $service_iptables_stop = <<SCRIPT
service iptables stop
SCRIPT
  # stop firewalld
  $systemctl_stop_firewalld = <<SCRIPT
systemctl stop firewalld.service
SCRIPT
  $etc_rc_conf_hostname = <<SCRIPT
sed -i '' "s/hostname=.*/hostname=$1/" /etc/rc.conf
SCRIPT
  # common settings on all machines
  $etc_hosts = <<SCRIPT
cat <<END >> /etc/hosts
192.168.0.4 puppet
192.168.0.5 nagiosserver
192.168.0.10 centos6
192.168.0.20 centos7
192.168.0.30 ubuntu14
192.168.0.40 freebsd10
END
SCRIPT
  # set puppet on clients
  $etc_puppet_puppet_conf = <<SCRIPT
cat <<END >> /etc/puppet/puppet.conf
[agent]
server = puppet
END
SCRIPT
  $usr_local_etc_puppet_puppet_conf = <<SCRIPT
# clean isc.freebsd.org information ad other cases
sed -i '' '/.*isc\.freebsd\.org.*/d' /usr/local/etc/puppet/puppet.conf
sed -i '' '/.*nyi\.freebsd\.org.*/d' /usr/local/etc/puppet/puppet.conf
sed -i '' '/.*\..*\.freebsd\.org.*/d' /usr/local/etc/puppet/puppet.conf
cat <<END >> /usr/local/etc/puppet/puppet.conf
[agent]
server = puppet
END
SCRIPT
  # provision puppet clients
  $epel6 = <<SCRIPT
yum -y install http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
SCRIPT
  $rhel_puppet = <<SCRIPT
yum -y install puppet
SCRIPT
  $epel7 = <<SCRIPT
yum -y install http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
SCRIPT
  $debian_puppet = <<SCRIPT
apt-get update
apt-get -y install puppet
SCRIPT
  $freebsd_puppet = <<SCRIPT
env ASSUME_ALWAYS_YES=YES pkg bootstrap
pkg2ng
pkg install -y puppet
cp -p /usr/local/etc/puppet/puppet.conf-dist /usr/local/etc/puppet/puppet.conf
echo 'puppet_enable="YES"' >> /etc/rc.conf
SCRIPT
  $puppet_pkgng = <<SCRIPT
puppet module install zleslie-pkgng
SCRIPT
  # puppetlabs on rhel6
  $puppetlabs_el6 = <<SCRIPT
yum -y install http://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm
SCRIPT
  # run puppet agent
  $puppet_agent = <<SCRIPT
puppet agent --no-daemonize --onetime --ignorecache --no-splay --verbose
SCRIPT
  # provision puppetmaster
  $linux_puppetmaster_configure = <<SCRIPT
cat <<END > /etc/puppet/puppetdb.conf
[main]
server = puppet
port = 8081
END
cat <<END >> /etc/puppet/puppet.conf
[master]
autosign = true
storeconfigs = true
storeconfigs_backend = puppetdb
reports = store, puppetdb
END
cat <<END > /etc/puppet/routes.yaml
master:
       facts:
         terminus: puppetdb
         cache: yaml
END
SCRIPT
  # provision puppetmaster
  $service_puppetmaster_ssl_setup = <<SCRIPT
service puppetmaster start
puppetdb ssl-setup
SCRIPT
  # provision puppetmaster
  $service_puppetmaster_restart = <<SCRIPT
service puppetdb start
service puppetmaster restart
SCRIPT
  # the actual provisions of machines
  config.vm.define "puppet" do |puppet|
    puppet.vm.provision :shell, :inline => "hostname puppet", run: "always"
    # don't let puppetmaster opening IPv6 ports
    puppet.vm.provision :shell, :inline => $linux_disable_ipv6, run: "always"
    puppet.vm.provision :shell, :inline => $etc_hosts
    puppet.vm.provision :shell, :inline => $puppetlabs_el6
    puppet.vm.provision :shell, :inline => "yum -y install puppet-server puppetdb puppetdb-terminus"
    puppet.vm.provision :shell, :inline => $linux_puppetmaster_configure
    puppet.vm.provision :shell, :inline => $service_puppetmaster_ssl_setup
    puppet.vm.provision :shell, :inline => $puppet_pkgng
    puppet.vm.provision :shell, :inline => $service_iptables_stop, run: "always"
    puppet.vm.provision :shell, :inline => $service_puppetmaster_restart, run: "always"
  end
  config.vm.define "centos6" do |centos6|
    centos6.vm.provision :shell, :inline => "hostname centos6", run: "always"
    centos6.vm.provision :shell, :inline => $etc_hosts
    centos6.vm.provision :shell, :inline => $epel6
    centos6.vm.provision :shell, :inline => $rhel_puppet
    centos6.vm.provision :shell, :inline => $etc_puppet_puppet_conf
    centos6.vm.provision :shell, :inline => $service_iptables_stop, run: "always"
    centos6.vm.provision :shell, :inline => $puppet_agent, run: "always"
  end
  config.vm.define "centos7" do |centos7|
    centos7.vm.provision :shell, :inline => "hostname centos7", run: "always"
    centos7.vm.provision :shell, :inline => $etc_hosts
    centos7.vm.provision :shell, :inline => $epel7
    centos7.vm.provision :shell, :inline => $rhel_puppet
    centos7.vm.provision :shell, :inline => $etc_puppet_puppet_conf
    centos7.vm.provision :shell, :inline => $systemctl_stop_firewalld, run: "always"
    centos7.vm.provision :shell, :inline => $puppet_agent, run: "always"
  end
  config.vm.define "ubuntu14" do |ubuntu14|
    ubuntu14.vm.provision :shell, :inline => "hostname ubuntu14", run: "always"
    ubuntu14.vm.provision :shell, :inline => $etc_hosts
    ubuntu14.vm.provision :shell, :inline => $debian_puppet
    ubuntu14.vm.provision :shell, :inline => $etc_puppet_puppet_conf
    ubuntu14.vm.provision :shell, :inline => "puppet agent --enable"
    ubuntu14.vm.provision :shell, :inline => "service puppet stop"
    ubuntu14.vm.provision :shell, :inline => $puppet_agent, run: "always"
  end
  config.vm.define "freebsd10" do |freebsd10|
    freebsd10.vm.provision :shell, :inline => "hostname freebsd10", run: "always"
    freebsd10.vm.provision :shell, :inline => $etc_hosts
    freebsd10.vm.provision "shell" do |s|
      s.inline = $etc_rc_conf_hostname
      s.args   = "freebsd10"
    end
    freebsd10.vm.provision :shell, :inline => $freebsd_puppet
    freebsd10.vm.provision :shell, :inline => $usr_local_etc_puppet_puppet_conf
    freebsd10.vm.provision :shell, :inline => $puppet_agent, run: "always"
  end
  # last provision nagiosserver - needs to know all exported nagios clients resources
  config.vm.define "nagiosserver" do |nagiosserver|
    nagiosserver.vm.provision :shell, :inline => "hostname nagiosserver", run: "always"
    nagiosserver.vm.provision :shell, :inline => $etc_hosts
    nagiosserver.vm.provision :shell, :inline => $epel6
    nagiosserver.vm.provision :shell, :inline => $rhel_puppet
    nagiosserver.vm.provision :shell, :inline => $etc_puppet_puppet_conf
    nagiosserver.vm.provision :shell, :inline => $service_iptables_stop, run: "always"
    nagiosserver.vm.provision :shell, :inline => $puppet_agent, run: "always"
  end
end
