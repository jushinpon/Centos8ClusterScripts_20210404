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
my @nodes = (1..13,15..24);# new nodes you want to install
`cp /root/Centos8ClusterScripts_20210404/Server/slurm.conf /usr/local/etc/`; # for slurm reconfig

for (@nodes){
$pm->start and next;

    my $nodeindex=sprintf("%02d",$_);
    my $nodename= "node"."$nodeindex";
    my $cmd = "ssh $nodename ";

    system ("scp  /usr/local/etc/slurm.conf root\@$nodename:/usr/local/etc/");
    if($?){`echo '$nodename scp failed!' >> failed_scp.txt`;}
        
    # the following is for a new setting only instead of scontrol reconfigure    
    system("$cmd 'rm -rf /var/spool/slurmd'");
	system("$cmd 'mkdir /var/spool/slurmd'");
	system("$cmd 'chown slurm: -R /var/spool/slurmd'");
	system("$cmd 'chmod 755 /var/spool/slurmd'");
	system("$cmd 'rm -f /var/log/slurmd.log'");
	system("$cmd 'touch /var/log/slurmd.log'");
	system("$cmd 'rm -rf /var/run/slurmd.pid'");
	system("$cmd 'touch /var/run/slurmd.pid'");
	system("$cmd 'chown slurm: /var/log/slurmd.log'");
	system("$cmd 'chown slurm: /var/run/slurmd.pid'");
	system("$cmd 'systemctl stop firewalld'");
	system("$cmd 'systemctl disable firewalld'");
	system("$cmd 'slurmd -C'");
	system("$cmd 'systemctl enable slurmd.service'");
	system("$cmd 'systemctl stop slurmd.service'");
	system("$cmd 'systemctl start slurmd.service'");

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

