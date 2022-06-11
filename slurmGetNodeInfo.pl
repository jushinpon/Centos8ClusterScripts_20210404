=b
This script goes through each node for getting node's information (using slurmd -C)
=cut
use warnings;
use strict;
use Parallel::ForkManager;
use Cwd;
use POSIX;
#my $currentPath = getcwd();
my $forkNo = 1;
#my $pm = Parallel::ForkManager->new("$forkNo");
#`touch scptest.dat`;
#`dd if=/dev/zero of=scptest.dat bs=1024 count=10`;
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
#NodeName=node01 NodeAddr=192.168.0.2 CPUs=24 State=UNKNOWN (slurm.conf)
#NodeName=node01 CPUs=24 Boards=1 SocketsPerBoard=1 CoresPerSocket=12 ThreadsPerCore=2 RealMemory=31868

#The following is for new version of slurm.conf
#NodeName=node03  CPUs=12 State=UNKNOWN RealMemory=31762 MemSpecLimit=512
#NodeName=master  CPUs=8 State=UNKNOWN RealMemory=11710 MemSpecLimit=1024
`rm -f ./slurmdOut.txt`;
`touch ./slurmdOut.txt`;

for (@nodes){
    my $nodeindex=sprintf("%02d",$_);
    my $nodename= "node"."$nodeindex";
    my $cmd = "ssh $nodename ";
    my $last = $_ + 1;
    chomp $last;
    my $ip = "192.168.0.$last";
    my $slurmd = `$cmd "slurmd -C"`;
    chomp $slurmd;
    $slurmd =~ s/\s+UpTime=.+$//;
    chomp $slurmd;
    $slurmd =~ m/.+RealMemory=(\d+)/;
    my $temp = $1 - 10;
    $slurmd =~ s/RealMemory=\d+/RealMemory=$temp/;
    `echo "$slurmd MemSpecLimit=512" >> ./slurmdOut.txt`;
    #print "$nodename, $ip, $slurmd\n";

}

#determine master node information
my $slurmd = `slurmd -C`;
chomp $slurmd;
$slurmd =~ s/\s+UpTime=.+$//;
chomp $slurmd;
$slurmd =~ m/.+RealMemory=(\d+)/;
my $temp = $1 - 10;
$slurmd =~ s/RealMemory=\d+/RealMemory=$temp/;
        
`echo "$slurmd MemSpecLimit=1024" >> ./slurmdOut.txt`;

print "\n##Showing dead nodes\n\n";
system("cat ./slurmdDead.txt");
print "\n***All Done\n";
    