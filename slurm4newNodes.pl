# install slurm for adding new nodes to cluster

use warnings;
use strict;
use Expect;
use Parallel::ForkManager;
use MCE::Shared;
use Cwd; #Find Current Path

my $forkNo = 50;
my $pm = Parallel::ForkManager->new("$forkNo");
my $expectT = 10;# time peroid for expect
my @nodes = (3,28,30,31,38);# new nodes you want to install
# install slurm for all new nodes
for (@nodes){		
	$pm->start and next;
    my $nodeindex=sprintf("%02d",$_);
    my $nodename= "node"."$nodeindex";
    unlink "/home/slurmDone_$nodename.txt";
	print "***$nodename is doing scp\n";
    system("scp ./ForNode/06slurm_slave.pl root\@$nodename:/root");
    my $exp = Expect->new;
	$exp = Expect->spawn("ssh -l root $nodename \n");	
	$exp->send ("rm -f nohup.out\n") if ($exp->expect($expectT,'#'));
	$exp->send ("nohup perl ./06slurm_slave.pl &\n") if ($exp->expect($expectT,'#'));
	#$exp -> send("\n") if ($exp->expect($expectT,'#'));
	$exp -> send("exit\n") if ($exp->expect($expectT,'#'));
	$exp->soft_close();
	$pm->finish;
} # end of loop
$pm->wait_all_children;

## check slurm installation status of each node
my $nodeNo = @nodes;
my $whileCounter = 0;
my $slurmCounter = 500;
while ($slurmCounter != $nodeNo){
	$whileCounter += 1;
	$slurmCounter = 0;
	sleep(20);

	for (@nodes){	
		my $nodeindex=sprintf("%02d",$_);
    	my $nodename= "node"."$nodeindex";
		if( -e "/home/slurmDone_$nodename.txt"){
			$slurmCounter += 1;			
			print "$nodename: Done!!!\n";
		}
		else{
			print "$nodename: slurm installation hasn't done\n";
		}		 
	}
	print "\n\n****Doing while times: $whileCounter\n";
	print "total node number need slurm to install: $nodeNo\n";
	print "Current node number with slurm installed: $slurmCounter\n\n";
}

##configure slurm
#chdir($current_path);
unlink "./newnodes_coreNo.txt";
`touch ./newnodes_coreNo.txt`;

tie my %coreNo, 'MCE::Shared';
tie my %socketNo, 'MCE::Shared';
tie my %threadcoreNo, 'MCE::Shared';
tie my %coresocketNo, 'MCE::Shared';
tie my %numaNo, 'MCE::Shared';

for (@nodes){	
	$pm->start and next;
    my $nodeindex=sprintf("%02d",$_);
    my $nodename= "node"."$nodeindex";
	my $exp = Expect->new;
	$exp = Expect->spawn("ssh -l root $nodename \n");	
# get CPU Number	
	$exp->send ("lscpu|grep \"^CPU(s):\" | sed 's/^CPU(s): *//g' \n") if ($exp->expect($expectT,'#'));
	$exp->expect($expectT,'-re','\d+');#before() keeps command, match() keeps number, after() keep left part+root@master#
	my $Mread = $exp->match();
	chomp $Mread;
    if ($Mread){
	  $coreNo{$nodename} = $Mread;
	  print "coreNo hash for $nodename , Mread: $Mread, $coreNo{$nodename}\n";
	  };
	$exp->soft_close();
	$pm->finish;
} # end of loop
$pm->wait_all_children;

for (@nodes){		
    my $nodeindex = sprintf("%02d",$_);
    my $nodename = "node"."$nodeindex";
	my $ip = "192.168.0.". ($_ +1);
	`echo "NodeName=$nodename NodeAddr=$ip CPUs=$coreNo{$nodename} State=UNKNOWN" >> ./newnodes_coreNo.txt`;
}
