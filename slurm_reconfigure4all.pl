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
#only for new nodes, if not use ssh_install.pl
my @nodes = (1..15,17..24);# new nodes you want to install
`cp /root/Centos8ClusterScripts_20210404/Server/slurm.conf /usr/local/etc/`; # for slurm reconfig
`cp /root/Centos8ClusterScripts_20210404/Server/cgroup.conf /usr/local/etc/`; # for slurm reconfig

for (@nodes){
$pm->start and next;

    my $nodeindex=sprintf("%02d",$_);
    my $nodename= "node"."$nodeindex";
    my $cmd = "ssh $nodename ";

    system ("scp  /usr/local/etc/slurm.conf root\@$nodename:/usr/local/etc/");
    system ("scp  /usr/local/etc/cgroup.conf root\@$nodename:/usr/local/etc/");
    if($?){`echo '$nodename scp failed!' >> failed_scp.txt`;}
        
    # the following is for a new setting only instead of scontrol reconfigure    
    system("$cmd 'systemctl restart slurmd'");

    my $temp = `$cmd 'systemctl status slurmd|egrep "failed|inactive"'`;
    if($temp){
        print "\$temp: $temp, $nodename failed\n";
        `$cmd 'systemctl restart slurmd'`;
        `scontrol update nodename=$nodename state=resume`;
        #sinfo|grep All|grep down|awk '{print $NF}'
    }
    else{
        print "\$temp: $temp,$nodename ok\n";
    }    
$pm->finish;
}
$pm->wait_all_children;

#check master node if it is used for computing
`systemctl restart slurmd`;

my $temp = `systemctl status slurmd|egrep "failed|inactive"`;
if($temp){
    print "\$temp: $temp, master node failed\n";
    `systemctl restart slurmd`;
    `scontrol update nodename=master state=resume`;
    #sinfo|grep All|grep down|awk '{print $NF}'
}
else{
    print "\$temp: $temp, master node ok\n";
} 
`systemctl restart slurmctld`;
`scontrol reconfigure`;
system("sinfo -R");

my @resume = `sinfo -R|grep -v REASON|awk '{print \$NF}'`;
chomp @resume;
for (@resume){
    chomp;
    print "resumed nodes: $_\n";
    system "scontrol update nodename=$_ state=resume";
}

print "\n***Final sinfo check\n";
system("sinfo -R");
