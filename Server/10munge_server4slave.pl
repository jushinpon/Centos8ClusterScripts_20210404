#!/usr/bin/perl
#munge setting for nodes developed by Prof. Shin-Pon Ju 2020/01/09
use strict;
use warnings;
use Expect;
use Parallel::ForkManager;

open my $ss,"< ./Nodes_IP.dat" or die "No Nodes_IP.dat to read"; 
my @temp_array=<$ss>;
my @avaIP=grep (($_!~m{^\s*$|^#}),@temp_array); # remove blank lines and comment lines
close $ss; 
for (@avaIP){
	$_  =~ s/^\s+|\s+$//;
	chomp;
	print "IP: $_\n";
}
my $forkNo = @avaIP;
print "forkNo: $forkNo\n";

my $pm = Parallel::ForkManager->new("$forkNo");

# find all IPs of available nodes 
$ENV{TERM} = "vt100";
my $pass = "xxxx"; ##For all roots of nodes

for (@avaIP){
	sleep(1);	
	$pm->start and next;
	$_ =~/192.168.0.(\d{1,3})/;#192.168.0.X
	my $temp= $1 - 1;
	my $nodeindex=sprintf("%02d",$temp);
	my $nodename= "node"."$nodeindex";
	chomp $nodename;
    print "**nodename**:$nodename\n";
    system("scp  /etc/munge/munge.key root\@$nodename:/etc/munge/");
    sleep(1);
    system("ssh $nodename \'ls -al /etc/munge/\'");	
    $pm->finish;
} # end of loop
$pm->wait_all_children;
sleep(1);
for (@avaIP){	
	$pm->start and next;
	$_ =~/192.168.0.(\d{1,3})/;#192.168.0.X
	my $temp= $1 - 1;
	my $nodeindex=sprintf("%02d",$temp);
	my $nodename= "node"."$nodeindex";
	chomp $nodename;
	print "**nodename**:$nodename\n"; 
	my $exp = Expect->new;
	$exp = Expect->spawn("ssh $nodename\n");	
	$exp->send ("chown munge: /etc/munge/munge.key\n") if ($exp->expect(2,'#'));
	$exp->send ("chmod 400 /etc/munge/munge.key\n") if ($exp->expect(2,'#'));
	$exp->send ("systemctl enable munge\n") if ($exp->expect(2,'#'));
	$exp->send ("systemctl start munge\n") if ($exp->expect(2,'#'));
	$exp->send ("munge -n\n") if ($exp->expect(2,'#'));
	$exp->send ("munge -n| unmunge \n") if ($exp->expect(2,'#'));	
	$exp -> send("exit\n") if ($exp->expect(2,'#'));
	$exp->soft_close();
    $pm->finish;
}
$pm->wait_all_children;
sleep(1);
print "***** WATCH OUT!!!!!\n";
print "***** Begin munge ssh decode check node by node!!!!!\n\n";
sleep(3);
for (@avaIP){	
	#$pm->start and next;
	$_ =~/192.168.0.(\d{1,3})/;#192.168.0.X
	my $temp= $1 - 1;
	my $nodeindex=sprintf("%02d",$temp);
	my $nodename= "node"."$nodeindex";
	chomp $nodename;
	print "**nodename**:$nodename\n";
	system("munge -n \| ssh $nodename unmunge");
	#$pm->finish;
}# for loop

