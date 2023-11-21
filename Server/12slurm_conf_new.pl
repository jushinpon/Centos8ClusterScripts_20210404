#!/usr/bin/perl
#this script can be used for reconfigure for slurm
#!!!!!!!!!!!! You need to provide correct partitions
#slurm default installation path:
#/usr/local
#/usr/local/etc
use warnings;
use strict;
use Expect;
use Parallel::ForkManager;
use MCE::Shared;


my %nodes = (
    161 => [1..42],#1,3,39..
    182 => [1..24],
    186 => [1..7],
    190 => [1..3]
    );

my $ip = `/usr/sbin/ip a`;    
$ip =~ /140\.117\.\d+\.(\d+)/;
my $cluster = $1;
$cluster =~ s/^\s+|\s+$//;
#print "\$cluster: $cluster\n";
my @allnodes = @{$nodes{$cluster}};#all possible nodes including those without service
my @nodes;
my @nodeIPs;
`rm -f ./slurmdDead.txt`;
`touch ./slurmdDead.txt`;

`rm -f ./scptest.dat`;
`touch ./scptest.dat`;#testing file for scp
for (@allnodes){#filtering the good ones
#$pm->start and next;
    my $nodeindex=sprintf("%02d",$_);
    my $nodename= "node"."$nodeindex";
    print "****Check $nodename status\n ";
    #`echo "***$nodename" >> $output`;
#use scp for ssh test
	system("scp -o ConnectTimeout=5 ./scptest.dat root\@$nodename:/root");    
    if($?){
		print "scp at $nodename failed\n";
        `echo "$nodename is currently dead." >> ./slurmdDead.txt`;

		next;
	}
	else{
		print "scp at $nodename ok for ssh test\n";
        push @nodes,$_;#keep node number
	}	
}    

`systemctl stop slurmctld.service`;# stop working slurmctld first
`systemctl stop slurmd.service`;# stop working slurmctld first
my $expectT = 3;# time peroid for expect
my $forkNo = @nodes;
my $pm = Parallel::ForkManager->new("$forkNo");
#****
#NodeName=node01 CPUs=16 Boards=1 SocketsPerBoard=1 CoresPerSocket=8 ThreadsPerCore=2 RealMemory=31836 MemSpecLimit=128

my $master4calculation = "yes"; #yes or no, whether to make the server to be a computing node
#my @partition = (
#'PartitionName=debug Nodes=node[01-24],master Default=YES MaxTime=1880 State=UP DisableRootJobs=YES',
##'PartitionName=AMD64Cores Nodes=node[02-03] Default=YES MaxTime=INFINITE State=UP',
#);

$ENV{TERM} = "vt100";
my $pass = "xxx"; ##For all roots of nodes

### Server setting 
system("rm -rf /var/spool/slurmctld");
system("mkdir /var/spool/slurmctld");
system("chown slurm: -R /var/spool/slurmctld");
system("chmod -R 755 /var/spool/slurmctld");
`rm -rf /var/run/slurmctld.pid`;
`touch /var/run/slurmctld.pid`;
`chown slurm:slurm /var/run/slurmctld.pid`;
#`chown -R slurm:root /var/spool`;
#`chown -R slurm:root /var/run`;
system("rm -f /var/log/slurmctld.log");
system("touch /var/log/slurmctld.log");
system("chown slurm:slurm /var/log/slurmctld.log");

system("rm -f /var/log/slurm_jobacct.log");
system("rm -f /var/log/slurm_jobcomp.log");

system("touch /var/log/slurm_jobacct.log /var/log/slurm_jobcomp.log");
system("chown slurm:slurm /var/log/slurm_jobacct.log /var/log/slurm_jobcomp.log");
system("firewall-cmd --zone=internal --add-port={6817/tcp,6818/udp} --permanent");
system(" firewall-cmd --reload");
sleep(1);


#`systemctl status slurmctld.service`;

if($master4calculation eq "yes"){
    `rm -rf /var/spool/slurmd`;
	`mkdir /var/spool/slurmd`;
	`chown slurm: -R /var/spool/slurmd`;
	`chmod 755 /var/spool/slurmd`;
	`rm -f /var/log/slurmd.log`;
	`touch /var/log/slurmd.log`;	
	`chown slurm: /var/log/slurmd.log`;
	#`rm -rf /var/run/slurmd.pid`;
	#`touch /var/run/slurmd.pid`;
	#`chown slurm:root /var/run/slurmd.pid`;
	
	#`systemctl stop firewalld`;
	#`systemctl disable firewalld`;
	`slurmd -C`;
    `systemctl enable slurmd.service`;
	`systemctl stop slurmd.service`;
	`systemctl start slurmd.service`;	
}

sleep(1);
######## start and enable slurm  for each node
for (@nodes){
	$pm->start and next;
    my $nodeindex=sprintf("%02d",$_);
    my $Nodename= "node"."$nodeindex";
    #$_ =~/192.168.0.(\d{1,3})/;
	#my $nodeID = $1 - 1;# node ID according to th fourth number of current IP
	#chomp($nodeID);
    #my $formatted_nodeID = sprintf("%02d",$nodeID);
    #my $Nodename="node"."$formatted_nodeID";
	my $exp = Expect->new;
	$exp = Expect->spawn("ssh $Nodename \n");
	$exp -> send("rm -rf /var/spool/slurmd \n") if ($exp->expect($expectT,'#'));
	$exp -> send("mkdir /var/spool/slurmd \n") if ($exp->expect($expectT,'#'));
	$exp -> send("chown slurm: -R /var/spool/slurmd \n") if ($exp->expect($expectT,'#'));
	$exp -> send("chmod 755 /var/spool/slurmd \n") if ($exp->expect($expectT,'#'));
	$exp -> send("rm -f /var/log/slurmd.log \n") if ($exp->expect($expectT,'#'));
	$exp -> send("touch /var/log/slurmd.log \n") if ($exp->expect($expectT,'#'));
	$exp -> send("rm -rf /var/run/slurmd.pid \n") if ($exp->expect($expectT,'#'));
	$exp -> send("touch /var/run/slurmd.pid \n") if ($exp->expect($expectT,'#'));
	$exp -> send("chown slurm: /var/log/slurmd.log \n") if ($exp->expect($expectT,'#'));
	$exp -> send("chown slurm: /var/run/slurmd.pid \n") if ($exp->expect($expectT,'#'));
	$exp -> send("systemctl stop firewalld\n") if ($exp->expect($expectT,'#'));
	$exp -> send("systemctl disable firewalld\n") if ($exp->expect($expectT,'#'));
	$exp -> send("slurmd -C \n") if ($exp->expect($expectT,'#'));
	$exp -> send("systemctl enable slurmd.service \n") if ($exp->expect($expectT,'#'));
	$exp -> send("systemctl stop slurmd.service \n") if ($exp->expect($expectT,'#'));
	$exp -> send("systemctl start slurmd.service \n") if ($exp->expect($expectT,'#'));
	#$exp -> send("systemctl status slurmd.service \n") if ($exp->expect($expectT,'#'));
	#$exp -> send(" \n") if ($exp->expect($expectT,'2'));
	$exp -> send("exit\n") if ($exp->expect($expectT,'#'));
	$exp->soft_close();
	$pm->finish;
} # end of loop
$pm->wait_all_children;
### start slurm for server


print "***** WATCH OUT!!!!!\n";
print "***** Begin slurmd check node by node!!!!!\n\n";
sleep(3);
if($master4calculation eq "yes"){
	print "***nodename: master\n";
	system("slurmd -C");
    # slurmd -C 
     my $slurmd = `slurmd -C|grep -v UpTime`;
     chomp $slurmd;
     `echo "$slurmd" >> ./for_slurm_conf.dat`;
	sleep(1);
}
for (@nodes){	
    my $nodeindex=sprintf("%02d",$_);
    my $nodename= "node"."$nodeindex";
    my $cmd = "ssh $nodename ";
    # slurmd -C 
    my $slurmd = `$cmd "slurmd -C|grep -v UpTime"`;
    chomp $slurmd;
    `echo "$slurmd" >> ./for_slurm_conf.dat`;

    my $exp = Expect->new;
	$exp = Expect->spawn("ssh $nodename \n");
	$exp -> send("slurmd -C \n") if ($exp->expect($expectT,'#'));	
	$exp -> send("exit\n") if ($exp->expect($expectT,'#'));
	$exp->soft_close();
	print "\n"; 
	sleep(1);
}# for loop
print "##Check for_slurm_conf.dat\n\n";
system("cat ./for_slurm_conf.dat");
print "\n********Activate slurmctld after exec slurm_reconfigure4all.pl!\n";
#To display the compute nodes: scontrol show nodes
#To display the job queue: scontrol show jobs
#To submit script jobs: sbatch -N2 script-file
