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
=cut
#!/usr/bin/perl
use strict;
use warnings;
use Cwd; #Find Current Path
use Parallel::ForkManager;
#$ENV{TERM} = "vt100";
#my $pass = "123"; ##For all roots of nodes
#
my $target = "master";# node01... not work currently
my @serverCMD = ('ibv_rc_pingpong -d rxe0 -g 1',
"udaddy","rdma_server",
"ib_send_bw -d rxe0 -i 1 -F --report_gbits",
"rping -s  -C 10 -v","ucmatose"
);
my @nodeCMD = ('ibv_rc_pingpong -d rxe0 -g 1',
"udaddy -s","rdma_client -s",
"ib_send_bw -d rxe0 -i 1 -F --report_gbits",
"rping  -c -C 10 -v -a","ucmatose -s");
open my $ss1,"< ../Server/Nodes_IP.dat" or die "No Nodes_IP.dat to read"; 
my @temp_array=<$ss1>;
my @avaIP=grep (($_!~m{^\s*$|^#}),@temp_array); # remove blank lines and comment lines
close $ss1; 
for (@avaIP){
	$_  =~ s/^\s+|\s+$//;
	chomp;
	print "IP: $_\n";
}

#
my $forkNo = 2;
print "forkNo: $forkNo\n";
my $pm = Parallel::ForkManager->new("$forkNo");

for my $cmdID (0..$#serverCMD){
chomp $cmdID;
my $serverCMD = $serverCMD[$cmdID];
my $nodeCMD = $nodeCMD[$cmdID];
for my $ip (@avaIP){	
   sleep(3);
   $ip =~/192.168.0.(\d{1,3})/;#192.168.0.X
   my $temp= $1 - 1;
   my $nodeindex=sprintf("%02d",$temp);
   my $nodename= "node"."$nodeindex";
   chomp $nodename;
if($target ne $nodename) {  
	for my $seq (0..1){
		$pm->start and next;
		if($seq == 0){# $target
			print "*** Check the connection between $target and $nodename\n";
			print "### $target $serverCMD\n";
			if($target eq "master"){
				system("$serverCMD");}
			else{
				print "test $target $serverCMD\n";
				system("ssh $target $serverCMD");
				print "after test $target $serverCMD\n";
				sleep(1);
			}
			print "\n";
		}
		else{
			print "### $nodename\n";
			system ("ssh $nodename $nodeCMD $target");
			print "\n\n";
		}
		sleep(1);		
		$pm->finish;
	}
$pm->wait_all_children;

} # end of ip loop
} # if 
} # end of cmd loop
## check slurm installation status of each node
