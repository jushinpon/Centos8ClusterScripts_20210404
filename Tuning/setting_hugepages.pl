=b
#selinux
sestatus

#getconf -a | grep PAGESIZE


=cut
use Parallel::ForkManager;
use Cwd;
use strict;
use warnings;
#my $currentPath = getcwd();
$forkNo = 1;
my $pm = Parallel::ForkManager->new("$forkNo");
my $prefix = `/usr/bin/date +\%F-\%H`;
chomp $prefix;
my $output = "/root/$prefix"."_diagnosis.dat";
`/usr/bin/rm -f $output`;
`/usr/bin/touch $output`;
#`touch scptest.dat`;
#`dd if=/dev/zero of=scptest.dat bs=1024 count=10`;
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

#scp test for all available nodes
`touch ./scptest.dat`;

my @nodes;
for my $a (@allnodes){
	my $scontrol = 1;
    $nodeindex=sprintf("%02d",$_);
    $nodename= "node"."$nodeindex";
    $cmd = "/usr/bin/ssh $nodename ";
    print "****Check $nodename status\n ";
    #`echo "***$nodename" >> $output`;
    #use scp for ssh test
	system("scp -o ConnectTimeout=5 ~/scptest.dat root\@$nodename:/root");    
    if($?){
		print "scp at $nodename failed\n";
		next;
	}
	else{
		print "scp at $nodename ok for ssh test\n";
        chomp $a;
        push @nodes,$a;
	}	

} 
   
#my @nodes1 = "";
for (@nodes){
    #$pm->start and next;
    $nodeindex=sprintf("%02d",$_);
    $nodename= "node"."$nodeindex";
    print "$nodename\n";
    $cmd = "ssh $nodename ";


    ## set unlimited ram memory
if(!`grep '* soft memlock unlimited' /etc/security/limits.conf`){
	`echo '* soft memlock unlimited' >> /etc/security/limits.conf`;
}
if(!`grep '* hard memlock unlimited' /etc/security/limits.conf`){
	`echo '* hard memlock unlimited' >> /etc/security/limits.conf`;
}
if(!`grep 'ulimit -l unlimited' /etc/profile`){
	`echo 'ulimit -l unlimited' >> /etc/profile`;
}
#* soft stack unlimited
#* hard stack unlimited
#* soft nproc unlimited
#* hard nproc unlimited
#* soft memlock unlimited
#* hard memlock unlimited

    #system("$cmd 'sed -i -e \"s|mirrorlist=|#mirrorlist=|g\" /etc/yum.repos.d/CentOS-*' ");
	#system("$cmd 'sed -i -e \"s|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g\" /etc/yum.repos.d/CentOS-*'");
	#system("$cmd 'dnf clean all'");
	#system("$cmd 'dnf update'");
    #$pm->finish;
}
#$pm->wait_all_children;
