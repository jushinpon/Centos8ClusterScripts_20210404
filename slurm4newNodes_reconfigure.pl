# install slurm for adding new nodes to cluster

use warnings;
use strict;
use Expect;
use Parallel::ForkManager;
use MCE::Shared;
use Cwd; #Find Current Path

my $forkNo = 50;
my $pm = Parallel::ForkManager->new("$forkNo");
my $expectT = 1;# time peroid for expect
#only for new nodes, if not use ssh_install.pl
`cp /root/Centos8ClusterScripts_20210404/Server/slurm.conf /usr/local/etc/`; # for slurm reconfig

my %nodes = (
    161 => [1..42],#1,3,39..
    182 => [1..24],
    186 => [1..7]
    );

my $ip = `/usr/sbin/ip a`;    
$ip =~ /140\.117\.\d+\.(\d+)/;
my $cluster = $1;
$cluster =~ s/^\s+|\s+$//;
#print "\$cluster: $cluster\n";
my @allnodes = @{$nodes{$cluster}};#get node information

`/usr/bin/touch ./scptest.dat`;
my @nodes;

for (@allnodes){
  my  $nodeindex=sprintf("%02d",$_);
  my  $nodename= "node"."$nodeindex";
    chomp $nodename;
    print "****Check $nodename status\n ";
    #`echo "***$nodename" >> $output`;
#use scp for ssh test
	system("scp -o ConnectTimeout=5 ./scptest.dat root\@$nodename:/root");    
    if($?){
		print "scp at $nodename failed\n";
		next;
		}
	else{
		print "scp at $nodename ok for ssh test\n";
        push @nodes,$_;
		}	
    
}
#for (@nodes){print "$_\n";}
#die;
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

