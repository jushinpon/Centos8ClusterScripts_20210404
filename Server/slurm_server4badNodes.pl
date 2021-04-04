#!/usr/bin/perl
#SLURM installation script developed by Prof. Shin-Pon Ju 2019/12/15
# You need to install munge for server and nodes first
use Expect;
use Parallel::ForkManager;
use MCE::Shared;
$expectT = 10;# time peroid for expect
$forkNo = 30;
my $pm = Parallel::ForkManager->new("$forkNo");
## get available IPs by reading or find them by ssh

system("systemctl stop slurmctld.service");
system("systemctl stop slurmd.service");

#open ss,"<./Nodes_IP.txt"; #generate by 05root_rsa.pl
#chomp (@avaIP=<ss>);# all available IPs
#close(ss);
#
@avaIP = qw/192.168.0.2/;

$ENV{TERM} = "vt100";
$pass = "123"; ##For all roots of nodes

######## begin install slurm in each node (need fork in the future)

for (@avaIP){	
	$pm->start and next;
	my $exp = Expect->new;
	$exp = Expect->spawn("ssh -l root $_ \n");	
	$exp->send ("systemctl stop slurmd.service\n") if ($exp->expect($expectT,'#'));
	$exp->send ("cd /home/slurm_rpms\n") if ($exp->expect($expectT,'#'));
	$exp -> send("dnf --nogpgcheck localinstall slurm-* -y\n") if ($exp->expect($expectT,'#'));
	$exp -> send("\n") if ($exp->expect($expectT,'#'));
	$exp -> send("exit\n") if ($exp->expect($expectT,'#'));
	$exp->soft_close();
	$pm->finish;
} # end of loop
$pm->wait_all_children;

## check slurm installation staus of each node
for (@avaIP){
    $_ =~/192.168.0.(\d{1,2})/;
	$nodeID = $1 - 1;# node ID according to th fourth number of current IP
	chomp($nodeID);
    $formatted_nodeID = sprintf("%02d",$nodeID);
    $Nodename="node"."$formatted_nodeID";

    print "**Nodename**:$Nodename\n"; 
    system"ssh root\@$Nodename \'ls -al /etc/slurm\'";   
    #my $exp = Expect->new;
	#$exp = Expect->spawn("ssh $nodename \n");
	#$exp -> send("ls /etc/slurm \n") if ($exp->expect($expectT,'#'));	
	#$exp -> send("exit\n") if ($exp->expect($expectT,'#'));
	#$exp->soft_close();
	print "\n"; 
	sleep(1);
}

