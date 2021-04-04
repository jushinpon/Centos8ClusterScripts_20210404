=beg
Modify the memlock in /etc/security/limits.conf for master and each node 
soft-roce configuration below:
https://community.mellanox.com/s/article/howto-configure-soft-roce
ibdev2netdev
=cut
#!/usr/bin/perl
use strict;
use warnings;

system("systemctl enable rdma");
system("systemctl start rdma");
system("yum install -y  libocrdma libibverbs libibverbs-utils infiniband-diags perftest");

#system("yum -y install libibverbs libibverbs-devel libibverbs-utils librdmacm librdmacm-devel librdmacm-utils");
my $hostname = `hostname`;
chomp $hostname;# need to chomp
my $hostfile = "/home/rdma_$hostname.txt"; # get the hostname for output file
unlink "$hostfile";
if(!`grep '* soft memlock unlimited' /etc/security/limits.conf`){
	`echo '* soft memlock unlimited' >> /etc/security/limits.conf`;
}
if(!`grep '* hard memlock unlimited' /etc/security/limits.conf`){
	`echo '* hard memlock unlimited' >> /etc/security/limits.conf`;
}

if(!-f "/etc/security/limits.d/rdma.conf"){# if no /etc/security/limits.d/rdma.conf, make this file	
	`touch /etc/security/limits.d/rdma.conf`;	
}

if(!`grep '* soft memlock unlimited' /etc/security/limits.d/rdma.conf`){
	`echo '* soft memlock unlimited' >> /etc/security/limits.d/rdma.conf`;
}
if(!`grep '* hard memlock unlimited' /etc/security/limits.d/rdma.conf`){
	`echo '* hard memlock unlimited' >> /etc/security/limits.d/rdma.conf`;
}
#get internet card name
my $temp = `ip a|grep "state UP"`;
my @temp = split "\n", $temp;
my @temp1 = grep (($_!~m{^\s*$}),@temp); # remove blank lines
my $upStateNo = @temp1;
if ($upStateNo > 1){die "The Number \($upStateNo\) of up state NIC is more than one!!\n";}
$temp1[0] =~ m{:\s+(.+)\s*:};
chomp $1;
print "NIC: $1\n";
if ($1 eq ""){die "No NIC exits\n";}
my $Nic_inner = $1;

system("rxe_cfg stop");
system("rxe_cfg start");
#print "1\n";
if($?){die "rxe_cfg start failed!!\n";}
#print "2\n";
system("rxe_cfg add $Nic_inner");
if($?){die "rxe_cfg add failed!!\n";}
system("rxe_cfg");
system("ibv_devices");
system("ibstat| tee $hostfile");
