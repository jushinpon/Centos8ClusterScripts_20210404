#!/usr/bin/perl
#system("$cmd 'sed -i -e \"s|mirrorlist=|#mirrorlist=|g\" /etc/yum.repos.d/CentOS-*' ");
	#system("$cmd 'sed -i -e \"s|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g\" /etc/yum.repos.d/CentOS-*'");
	#system("$cmd 'dnf clean all'");
	#system("$cmd 'dnf update'");

#systemctl status mcelog.service
#systemctl disable mcelog.service
#
#dnf install rasdaemon -y
#
#systemctl start rasdaemon.service
#systemctl enable rasdaemon.service
use strict;
use warnings;

my %nodes = (
    161 => [1..42],#1,3,39..
    182 => [1..24],
    186 => [1..7]
    );

my $ip = `/usr/sbin/ip a`;    
$ip =~ /140\.117\.\d+\.(\d+)/;
my $cluster = $1;
$cluster =~ s/^\s+|\s+$//;

my @allnodes = @{$nodes{$cluster}};#get node information

`touch ./scptest.dat`;#make a scp test file to skip bad nodes

my @nodes;
my $nodeindex;
my $nodename;
my $cmd;

for (@allnodes){
    chomp;
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
		#print "scp at $nodename ok for ssh test\n";
  		push @nodes, $_;
	}	
} 

chomp @nodes;

my %nfs;#looking for node nfs folder
for (@nodes){
    my $nodeindex = sprintf("%02d",$_);
    my $nodename = "node"."$nodeindex";
    $cmd = "/usr/bin/ssh $nodename ";
# could have trouble if more than one folders you want to collect	
    my $temp = `$cmd 'lscpu |grep "Model name:"|grep AMD|grep -v grep'`; 
	#print "###temp: $temp\n";       
	if($temp){#AMD cpu
		print "CPU brand of $nodename is $temp\n";
		system("$cmd 'sed -i -e \"s|mirrorlist=|#mirrorlist=|g\" /etc/yum.repos.d/CentOS-*' ");
		system("$cmd 'sed -i -e \"s|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g\" /etc/yum.repos.d/CentOS-*'");
		system("$cmd 'dnf clean all'");
		system("$cmd 'dnf update -y'");
		#modification start
		system("$cmd 'systemctl disable mcelog.service'");
		system("$cmd 'dnf install -y rasdaemon'");
		system("$cmd 'systemctl start rasdaemon.service'");
		system("$cmd 'systemctl enable rasdaemon.service'");

	}
	else{
		next;
		#print "CPU brand of $nodename is not AMD \n";
	}

}
