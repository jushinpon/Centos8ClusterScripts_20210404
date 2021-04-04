=beg
Modify the memlock in /etc/security/limits.conf for master and each node 
soft-roce configuration below:
https://community.mellanox.com/s/article/howto-configure-soft-roce
Nodes_IP.dat is required

5. Test connectivity.

- On the server:

# ibv_rc_pingpong -d rxe0 -g 1

- On the client:

# ibv_rc_pingpong -d rxe0 -g 1 <server_management_ip>

https://www.cnblogs.com/kaishirenshi/p/10286307.html

tool script:
https://github.com/Mellanox/mlnx-tools.git
=cut
#!/usr/bin/perl
use strict;
use warnings;
use Cwd; #Find Current Path
use Parallel::ForkManager;
system("systemctl enable rdma");
system("systemctl start rdma");
system("yum install -y libibverbs libibverbs-utils infiniband-diags perftest");
#system("yum -y install libibverbs libibverbs-devel libibverbs-utils librdmacm librdmacm-devel librdmacm-utils");
#
#[root@localhost ~]# more /etc/security/limits.d/rdma.conf
## configuration for rdma tuning
#*** soft memlock unlimited
#*** hard memlock unlimited
## modify memlock
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

#Reading required information for node 
open my $ss,"< ../Server/Server_setting.dat" or die "No Server_setting.dat to open.\n $!";
my @temp_array = <$ss>;
close $ss; 

my @temp_array1=grep (($_!~m{^\s*$|^#}),@temp_array); # remove blank lines
my %ServerSetting; # keep all information for Server setting
for (@temp_array1){
	$_  =~ s/^\s+|\s+$//;
	my @temp = split (/=/,$_) ;
	$temp[0]  =~ s/^\s+|\s+$//;
	chomp ($temp[0]);
	$temp[1]  =~ s/^\s+|\s+$//;
	chomp ($temp[1]);
	$ServerSetting{$temp[0]} = $temp[1] ;
}

#print "$ServerSetting{if_private}\n";
system("rxe_cfg stop");
system("rxe_cfg start");
#print "1\n";
if($?){die "rxe_cfg start failed!!\n";}
#print "2\n";
system("rxe_cfg add $ServerSetting{if_private}");
if($?){die "rxe_cfg add failed!!\n";}
system("rxe_cfg");
system("ibv_devices");
system("ibstat");
`ibstat`=~ m{(rxe0)};
#print "$1\n";
if(! $1){die "no rxe0 for soft-roce\n"}
#
#$ENV{TERM} = "vt100";
#my $pass = "123"; ##For all roots of nodes
#
open my $ss1,"< ../Server/Nodes_IP.dat" or die "No Nodes_IP.dat to read"; 
@temp_array=<$ss1>;
my @avaIP=grep (($_!~m{^\s*$|^#}),@temp_array); # remove blank lines and comment lines
close $ss1; 
for (@avaIP){
	$_  =~ s/^\s+|\s+$//;
	chomp;
	print "IP: $_\n";
}
#
my $forkNo = @avaIP;
print "forkNo: $forkNo\n";
#my $forkNo = 30;
my $pm = Parallel::ForkManager->new("$forkNo");

for (@avaIP){	
   sleep(3);
	$pm->start and next;
	$_ =~/192.168.0.(\d{1,3})/;#192.168.0.X
	my $temp= $1 - 1;
    my $nodeindex=sprintf("%02d",$temp);
    my $nodename= "node"."$nodeindex";
    chomp $nodename;
    unlink "/home/rdma_$nodename.txt";
    
    print "**nodename**:$nodename\n";
    system("ssh $nodename \'rm -f /root/nohup.out\'");
# if ($?){print "BAD: ssh $nodename \'rm -f /root/*.pl\' failed\n";};    
#    system("ssh $nodename \'rm -rf /root/*.txt\'");
# if ($?){print "BAD: ssh $nodename \'rm -rf /root/*.txt\' failed\n";};    
#    sleep(1);
    system("scp  ./softrdma_slave.pl root\@$nodename:/root");
 if ($?){die "scp softrdma_slave.pl failed\n";};    
    sleep(1);	
    system("ssh $nodename \'nohup perl softrdma_slave.pl &\'");
$pm->finish;
} # end of loop
$pm->wait_all_children;
## check slurm installation status of each node
my $nodeNo = @avaIP;
my $whileCounter = 0;
my $rdmaCounter = 50;
while ($rdmaCounter != $nodeNo){
	$whileCounter += 1;
	$rdmaCounter = 0;

	for (@avaIP){	
		$_ =~/192.168.0.(\d{1,3})/;#192.168.0.X
		my $temp= $1 - 1;
		my $nodeindex=sprintf("%02d",$temp);
		my $nodename= "node"."$nodeindex";
		#print "**nodename**:$nodename\n";
		if( -e "/home/rdma_$nodename.txt"){
			$rdmaCounter += 1;			
			print "$nodename: Done!!!\n";
		}
		else{
			print "$nodename: rdma modification hasn't done\n";
		}		 
	}
	print "\n\n****Doing while times: $whileCounter\n";
	print "total node number need rdma to set: $nodeNo\n";
	print "Current node number with rdma done: $rdmaCounter\n\n";
	sleep(20);
}

###GUID
