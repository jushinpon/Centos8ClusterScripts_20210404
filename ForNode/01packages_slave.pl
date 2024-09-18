#!/usr/bin/perl
use strict;
use warnings;

## set unlimited ram memory
if(!`grep '* soft memlock unlimited' /etc/security/limits.conf`){
	`echo '* soft memlock unlimited' >> /etc/security/limits.conf`;
}
if(!`grep '* hard memlock unlimited' /etc/security/limits.conf`){
	`echo '* hard memlock unlimited' >> /etc/security/limits.conf`;
}
if(!`grep 'ulimit -l unlimited' /etc/profile`){
	`echo 'ulimit -l unlimited' >> /etc/profile`;
}

system(". /etc/profile");

system("rm -rf /var/run/dnf.pid");
system('dnf -y groupinstall "Development Tools"');
system("yum install 'dnf-command(config-manager)'");
system("dnf install dnf-plugins-core -y");
system("dnf config-manager --set-enable powertools");
`dnf remove -y cockpit`;# not use this web manager tool for cluster
my @package = ("vim", "wget", "net-tools", "epel-release", "htop", "make"
			, "gcc-c++", "nfs-utils","yp-tools", "gcc-gfortran","psmisc","perl-Expect","gcc-gfortran","xorg-x11-server-Xorg","xorg-x11-xauth"
			,"perl-MCE-Shared","perl-Parallel-ForkManager","tmux","perl-CPAN"
			, "ypbind" , "rpcbind","xauth","oddjob-mkhomedir","perl-Statistics-Descriptive","libibverbs"
			,"libibverbs-utils","infiniband-diags","perftest","libatomic");
system ("dnf -y install perl* --nobest --skip-broken");# for perl* only
for (@package){system("dnf -y install $_");}
system("echo \'yes\'|cpan App::cpanminus");
system("cpanm Env::Modify --force");
system("cpanm Parallel::ForkManager --force");
system("cpanm Expect --force");
system("cpanm Statistics::Descriptive --force");
#system("cpanm MCE::Shared --force");

#make ssh login much faster
#set GSSAPIAuthentication to no  
`sed -i "/GSSAPIAuthentication/d" /etc/ssh/sshd_config`;#remove old setting first
`sed -i '\$ a GSSAPIAuthentication no' /etc/ssh/sshd_config`;# $ a for sed appending
#set GSSAPIAuthentication to no  
`sed -i "/UseDNS/d" /etc/ssh/sshd_config`;#remove old setting first
`sed -i '\$ a UseDNS no' /etc/ssh/sshd_config`;# $ a for sed appending

system("systemctl restart sshd");

#system("perl -p -i.bak -e 's/.*GSSAPIAuthentication.+/GSSAPIAuthentication no/;' /etc/ssh/sshd_config");
#system("perl -p -i.bak -e 's/.*UseDNS.+/UseDNS no/;' /etc/ssh/sshd_config");
system("killall -9 dnf");
system("systemctl restart sshd");
# disable automatic updating
system("systemctl stop dnf-automatic");
system("systemctl disable dnf-automatic");
system("dnf remove dnf-automatic -y");
system("systemctl stop dnf-makecache.timer");
system("systemctl disable dnf-makecache.timer");

system("dnf -y upgrade");
