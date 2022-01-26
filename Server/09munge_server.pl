#!/usr/bin/perl
#SLURM installation script developed by Prof. Shin-Pon Ju 2019/12/15
use strict;
use warnings;
use Expect;
use Parallel::ForkManager;

my $newnodes = "no"; # no for brand new installation, yes for adding new nodes into cluster

if ($newnodes eq "no"){
	system("yum install -y 'dnf-command(config-manager)'");
	system("dnf install dnf-plugins-core -y");
	system("dnf config-manager --set-enable powertools");
}

open my $ss,"< ./Nodes_IP.dat" or die "No Nodes_IP.dat to read"; 
my @temp_array=<$ss>;
my @avaIP=grep (($_!~m{^\s*$|^#}),@temp_array); # remove blank lines and comment lines
close $ss; 
for (@avaIP){
	$_  =~ s/^\s+|\s+$//;
	chomp;
	print "IP: $_\n";
}
my $forkNo = @avaIP;
print "forkNo: $forkNo\n";

my $pm = Parallel::ForkManager->new("$forkNo");

# find all IPs of available nodes 
$ENV{TERM} = "vt100";
#my $pass = ""; ##For all roots of nodes
#=bigin
for (@avaIP){
	sleep(3);
	$pm->start and next;
	$_ =~/192.168.0.(\d{1,3})/;#192.168.0.X
	my $temp= $1 - 1;
    my $nodeindex=sprintf("%02d",$temp);
    my $nodename= "node"."$nodeindex";
    chomp $nodename;
    print "**nodename**:$nodename\n";    

    my $exp = Expect->new;
	$exp = Expect->spawn("ssh $nodename\n");
	$exp->send ("rm -f nohup.out \n") if ($exp->expect(2,'#'));
	$exp->send ("nohup perl 05munge_slave.pl \n") if ($exp->expect(2,'#'));
	$exp -> send("exit\n") if ($exp->expect(2,'#'));
	$exp->soft_close();
    $pm->finish;
    sleep(2);	
}
$pm->wait_all_children;
sleep(1);

if ($newnodes eq "no"){# new cluster deployment if $newnodes = "no"

	system("systemctl stop munge");
	system("killall munged");
	
	# Removing the old slurm setting
	`dnf remove mariadb-server mariadb-devel -y`;
	sleep(1);
	#Munge is an authentication tool used to identify messaging from the Slurm machines
	`dnf remove slurm munge munge-libs munge-devel -y`;
	sleep(1);
	if(`grep 'slurm' /etc/passwd`){#remove the old slurm account
		system("userdel -r slurm");
	}
	
	if(`grep 'munge' /etc/passwd`){#remove the old slurm account
		print "**Response from grep 'munge' /etc/passwd: True \n";
		my $temp = `userdel -r munge`;
		print "**Response from userdel -r munge: $temp \n"; #empty is good
			if($temp=~/currently used by process (\d+)/){
				system("kill $1");
				system("userdel -r munge");
				}
	}
	
	### End of removing old munge setting
	
	system("dnf install mariadb-server mariadb-devel -y");
	
	#Create the global users:
	#Slurm and Munge require consistent UID and GID across every node in the cluster.
	
	
	#For all the nodes, before you install Slurm or Munge:
	my $MUNGEUSER=950;
	`groupadd -g 950 munge`;
	`useradd  -m -c "MUNGE Uid 'N' Gid Emporium" -d /var/lib/munge -u 95 -g munge  -s /sbin/nologin munge`;
	my $SLURMUSER=951;
	`groupadd -g 951 slurm`;
	`useradd  -m -c "SLURM workload manager" -d /var/lib/slurm -u 951 -g slurm  -s /bin/bash slurm`;
	
	#install Munge for the server
	system("rm -rf /etc/munge");
	system("rm -rf  /var/log/munge");
	system("rm -rf  /var/lib/munge");
	
	system("dnf install munge munge-libs munge-devel -y");
	system("chown -R munge: /etc/munge/ /var/log/munge/");
	system("chmod 0700 /etc/munge/ /var/log/munge/");
	system("chmod 0711 /var/lib/munge/");# no this on https://www.slothparadise.com/how-to-install-slurm-on-centos-7-cluster/
	
	unlink "/etc/munge/munge.key";
	system("/usr/sbin/create-munge-key -r");
	system("dd if=/dev/urandom bs=1 count=1024 > /etc/munge/munge.key");
	system("chown munge: /etc/munge/munge.key");
	system("chmod 400 /etc/munge/munge.key");
	sleep(1);
	
	system("systemctl enable munge");
	system("systemctl start munge");
}

print "\n\n ***** test munge by munge -n\n\n";
system("munge -n");
system("munge -n| unmunge");
system("remunge");

## check node setting status of each node
my $nodeNo = @avaIP;
my $whileCounter = 0;
my $Counter = 10000;
print "\n\n";
while ($Counter != $nodeNo){
	$whileCounter += 1;
	$Counter = 0;

	for (@avaIP){	
		$_ =~/192.168.0.(\d{1,3})/;#192.168.0.X
		my $temp= $1 - 1;
		my $nodeindex=sprintf("%02d",$temp);
		my $nodename= "node"."$nodeindex";
		#print "**nodename**:$nodename\n";
		if( -e "/home/munge_$nodename.txt"){
			$Counter += 1;			
			print "$nodename: munge check file exits!!!\n";
		}
		else{
			print "$nodename: setting hasn't done\n";
		}		 
	}
	print "\n\n****Doing while times: $whileCounter\n";
	print "total node number need to do the setting: $nodeNo\n";
	print "Current node number with setting done: $Counter\n\n";
	sleep(20);
}
#=cut
## check whether setting status of each node is OK
print "Watch out! Check whether munge at each node has been correctly installed!\n\n";
for (@avaIP){	
	$_ =~/192.168.0.(\d{1,3})/;#192.168.0.X
	my $temp= $1 - 1;
	my $nodeindex=sprintf("%02d",$temp);
	my $nodename= "node"."$nodeindex";
	chomp $nodename;
	$temp = `cat /home/munge_$nodename.txt`;
	if($temp =~ m{(munge munge)}){
		chomp $1;
		print "$nodename: \"$1\" exists, munge installation is ok\n";
	}
	else{
		print "***$nodename munge setting has problems. See /home/munge_$nodename.txt\n";
	}			 
}
print "\n\n If everything ok, conduct \"10munge_server4slave.pl\"\n\n";
