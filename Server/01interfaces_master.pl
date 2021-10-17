#!/usr/bin/perl

#CentOS 8 one click to set up Server
########## Things to know first 
#1. You need to check the internet card name before installation (ls /etc/sysconfig/network-scripts|grep ifcfg-*)
#ifup ifcfg-enp0s3 (if the internet card cfg file is ifcfg-enp0s3)
#yum -y install net-tools
##****** perl -v to make sure Perl has been installed!!!!!!!!!!!!
#2. try ip addr
#3. for geany: export DISPLAY=:0.0 into /etc/profile 

## basic setting
#/etc/ssh/sshd_config
#＃Port 22 -> systemctl restart sshd.service
#firewall-cmd zone=external add-port=10837/tcp permanent
#PermitRootLogin no

use strict;
use warnings;
use Cwd; #Find Current Path

open my $pack,"> ./FailedPackageInstall.dat";
#system("systemctl stop NetworkManager");
#system("systemctl disable NetworkManager");

#Reading required information for Server 

open my $ss,"< ./Server_setting.dat" or die "No Server_setting.dat to open.\n $!";
my @temp_array = <$ss>;
close $ss; 

my @temp_array1=grep (($_!~m{^\s*$|^#}),@temp_array); # remove blank lines
my % ServerSetting; # keep all information for Server setting
for (@temp_array1){
	$_  =~ s/^\s+|\s+$//;
	my @temp = split (/=/,$_) ;
	$temp[0]  =~ s/^\s+|\s+$//;
	chomp ($temp[0]);
	$temp[1]  =~ s/^\s+|\s+$//;
	chomp ($temp[1]);
	$ServerSetting{$temp[0]} = $temp[1] ;
}
# set the domain name for our cluster
system("domainname $ServerSetting{domainname}");
system("hostname master");
system("echo master > /etc/hostname");
system("hostnamectl set-hostname master");# set permanent hostname 
system("nisdomainname $ServerSetting{domainname}");

# get MAC of each internet card
my %mac;
for ($ServerSetting{if_internet},$ServerSetting{if_private}){
      my $ipne = `ip add show $_`;      
      $ipne =~ /(\w+:\w+:\w+:\w+:\w+:\w+)/;# the first matched item is mac!
      chomp $1;
      $mac{$_}="$1";  
}
#
##internet setting
if($ServerSetting{machinetype} ne "virtualbox"){
`echo "BOOTPROTO=static" > /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_internet}`;#open a new file
`echo "DNS1=$ServerSetting{dns_nameservers1}" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_internet}`;
`echo "DNS2=$ServerSetting{dns_nameservers2}" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_internet}`;
`echo "GATEWAY=$ServerSetting{gateway}" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_internet}`;
`echo "DEVICE=$ServerSetting{if_internet}" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_internet}`;#append the data into the file
`echo "NAME=$ServerSetting{if_internet}" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_internet}`;
`echo "ONBOOT=yes" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_internet}`;
`echo "IPADDR=$ServerSetting{IP_address}" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_internet}`;
`echo "NETMASK=$ServerSetting{netmask}" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_internet}`;
`echo "HWADDR=$mac{$ServerSetting{if_internet}}" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_internet}`; 
`echo "DEFROUTE=yes" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_internet}`;
`echo "TYPE=Ethernet" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_internet}`;
#
#private interface setting
`echo "BOOTPROTO=static" > /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_private}`;
`echo "DEVICE=$ServerSetting{if_private}" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_private}`;
`echo "NAME=$ServerSetting{if_private}" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_private}`;
`echo "ONBOOT=yes" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_private}`;
`echo "IPADDR=192.168.0.101" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_private}`;
`echo "NETMASK=255.255.255.0" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_private}`;
`echo "BROADCAST=192.168.0.255" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_private}`;
`echo "HWADDR=$mac{$ServerSetting{if_private}}" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_private}`; 
`echo "TYPE=Ethernet" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_private}`;
`echo "MTU=$ServerSetting{MTU}" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_private}`;

	#restart networking
	for ($ServerSetting{if_internet},$ServerSetting{if_private}){
		system("ifdown $_ ");## stop this NIC and force it to use new seeting by the following command 
		system("ip addr flush dev $_");## remove all previous setting (because we want to assign new informatio)  
		system("ifup $_"); ## use new setting
	}
}
system("yum install -y 'dnf-command(config-manager)'");
system("dnf install dnf-plugins-core -y");
system("dnf config-manager --set-enable powertools");


system("rm -rf /var/run/yum.pid");
#"iptables-services" not installed for Centos 8, replaced by "firewalld"
my @package = ("vim", "wget", "net-tools", "epel-release", "htop", "make","numactl-devel","fail2ban"
			, "openssh*", "nfs-utils", "ypserv" ,"yp-tools","geany","psmisc"
			,"firewalld", "ypbind" , "rpcbind","perl-Expect","gcc-gfortran","xorg-x11-server-Xorg","xorg-x11-xauth"
			,"perl-MCE-Shared","perl-Parallel-ForkManager","tmux","perl-CPAN","yum-utils","dos2unix");
#my $packcounter;
#my @failedPack;
system ("dnf -y install perl* --nobest --skip-broken");# for perl* only
foreach(@package){
	system("dnf -y install $_");
	if($?){
		print $pack "$_ installation failed!!!!!\n";
	}		
}

###install intel MKL

system("yum-config-manager --add-repo https://yum.repos.intel.com/mkl/setup/intel-mkl.repo");
if($?){die "add intel repo failed!\n";}
system("rpm --import https://yum.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB");
if($?){die "import intel repo key failed!\n";}
system("yum install -y intel-mkl");

#system("systemctl start cockpit");
#system("systemctl enable cockpit");
system("systemctl mask iptables");


#system("cpan Env::Modify --force");
system("echo \'yes\'|cpan App::cpanminus");
system("cpanm Env::Modify --force");
system("cpanm Parallel::ForkManager --force");
system("cpanm Expect --force");
system("cpanm Statistics::Descriptive --force");
system("cpanm MCE::Shared --force");

#system("cpan install IPC::PerlSSH");
if($?){
		print $pack "Env::Modify installation failed!!!!!\n";
	}
#cpan App::cpanminus
close($pack);
system("dnf -y upgrade");
#set x11 forwarding: enable x11 forwarding  
`sed -i "/X11Forwarding/d" /etc/ssh/sshd_config`;#remove old setting first
`sed -i '\$ a X11Forwarding yes' /etc/ssh/sshd_config`;# $ a for sed appending
#make ssh login much faster
#set GSSAPIAuthentication to no  
`sed -i "/GSSAPIAuthentication/d" /etc/ssh/sshd_config`;#remove old setting first
`sed -i '\$ a GSSAPIAuthentication no' /etc/ssh/sshd_config`;# $ a for sed appending
#set GSSAPIAuthentication to no  
`sed -i "/UseDNS/d" /etc/ssh/sshd_config`;#remove old setting first
`sed -i '\$ a UseDNS no' /etc/ssh/sshd_config`;# $ a for sed appending

system("systemctl restart sshd");

system("dnf install -y chrony");#time sync
system("systemctl start chronyd");#time sync
system("systemctl enable chronyd");#time sync
system("timedatectl set-timezone Asia/Taipei");## setting timezone

#system ("rm -rf geany-themes");
#system ("git clone https://github.com/codebrainz/geany-themes.git");
#my $current_path = getcwd;# get the current path dir
#chdir("$current_path/geany-themes");
#system (" bash install.sh");

# disable automatic updating
system("systemctl stop dnf-automatic");
system("systemctl disable dnf-automatic");
system("dnf remove dnf-automatic -y");
system("systemctl stop dnf-makecache.timer");
system("systemctl disable dnf-makecache.timer");
# setting parameters in /etc/profile and then source it
#if(!`grep 'export export DISPLAY=:0.0' /etc/profile`){
#`echo 'export DISPLAY=:0.0' >> /etc/profile`;
#}
#system(". /etc/profile");
#if($?) {print ". /etc/profile failed!!!\n";}

print "\n\n***###00interfaces_master.pl: set internet card done******\n\n";
print "Please check FailedPackageInstall.dat!!!\n";
