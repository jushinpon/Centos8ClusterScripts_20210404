# install slurm for adding new nodes to cluster

use warnings;
use strict;
use Expect;
use Parallel::ForkManager;
use MCE::Shared;
use Cwd; #Find Current Path

my %nodes = (
    161 => [1..42],#1,3,39..
    182 => [1..24],
    186 => [1..7],
    195 => [1..7],
    190 => [1..3]
    );

my $ip = `/usr/sbin/ip a`;    
$ip =~ /14\d\.1\d+\.\d+\.(\d+)/;
my $cluster = $1;
$cluster =~ s/^\s+|\s+$//;
#print "\$cluster: $cluster\n";
my @allnodes = @{$nodes{$cluster}};#all possible nodes including those without service
my @nodes;
my @nodeIPs;

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

#my $forkNo = 50;
#my $pm = Parallel::ForkManager->new("$forkNo");
#my $expectT = 10;# time peroid for expect
#only for new nodes, if not use ssh_install.pl
#my @nodes = (1..18,20..28,30..42);# new nodes you want to install

for (@nodes){
#$pm->start and next;
    my $nodeindex=sprintf("%02d",$_);
    my $nodename= "node"."$nodeindex";
    my $mixed = `scontrol show node $nodename|grep MIXED`;
    if ($mixed){print "node with MIXED state: $nodename\n";
        system("squeue |grep $nodename| awk \'{print \$1}'|xargs scancel");
    }
        
#$pm->finish;
}
#$pm->wait_all_children;scron