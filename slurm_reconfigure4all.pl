# install slurm for adding new nodes to cluster

use warnings;
use strict;
use Expect;
use Parallel::ForkManager;
use MCE::Shared;
use Cwd; #Find Current Path

`cp /root/Centos8ClusterScripts_20210404/Server/slurm.conf /usr/local/etc/`; # for slurm reconfig
`cp /root/Centos8ClusterScripts_20210404/Server/cgroup.conf /usr/local/etc/`; # for slurm reconfig
`cp /root/Centos8ClusterScripts_20210404/Server/slurmdbd.conf /usr/local/etc/`; # for slurm reconfig
#`rm -f /usr/local/etc/slurmdbd.conf`; # for slurm reconfig
`chown root:root  /usr/local/etc/slurm.conf`;
`chmod 644 /usr/local/etc/slurm.conf`;
#`chown slurm:slurm  /usr/local/etc/slurm.conf`;
`chown root:root  /usr/local/etc/cgroup.conf`;
`chmod 644 /usr/local/etc/cgroup.conf`;
#`chown slurm:slurm  /usr/local/etc/cgroup.conf`;
`chown slurm:slurm  /usr/local/etc/slurmdbd.conf`;
`chmod 600 /usr/local/etc/slurmdbd.conf`;

`rm -f /var/log/slurmdbd.log`;
`touch /var/log/slurmdbd.log`;
`chown slurm:slurm /var/log/slurmdbd.log`;
`chmod 644 /var/log/slurmdbd.log`;

`rm -f /var/run/slurmdbd.pid`;
`touch /var/run/slurmdbd.pid`;
`chown slurm:slurm /var/run/slurmdbd.pid`;
`chmod 644 /var/run/slurmdbd.pid`;

#`chown root:root  /usr/local/etc/slurmdbd.conf`;
my %nodes = (
    161 => [1..42],#1,3,39..
    182 => [1..4,6..15,17..24],
    #182 => [1..4,6..15,17..24],
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

my $forkNo = 50;
my $pm = Parallel::ForkManager->new("$forkNo");
my $expectT = 10;# time peroid for expect
#only for new nodes, if not use ssh_install.pl
#my @nodes = (1..18,20..28,30..42);# new nodes you want to install

for (@nodes){
$pm->start and next;

    my $nodeindex=sprintf("%02d",$_);
    my $nodename= "node"."$nodeindex";
    my $cmd = "ssh $nodename ";
    system("scp  ./slurm_rotate.txt root\@$nodename:/etc/logrotate.d/slurm");
    system ("scp  /usr/local/etc/slurm.conf root\@$nodename:/usr/local/etc/");
    system ("scp  /usr/local/etc/cgroup.conf root\@$nodename:/usr/local/etc/");
    if($?){`echo '$nodename scp failed!' >> failed_scp.txt`;}
        
    # the following is for a new setting only instead of scontrol reconfigure    
    system("$cmd 'systemctl restart slurmd'");
    system("$cmd 'systemctl enable slurmd'");

    my $temp = `$cmd 'systemctl status slurmd|egrep "failed|inactive"'`;
    if($temp){
        print "\$temp: $temp, $nodename failed\n";
        `$cmd 'systemctl restart slurmd'`;
        system("$cmd 'systemctl enable slurmd'");

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
`systemctl restart slurmctld`;

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
`systemctl restart slurmdbd`;
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
