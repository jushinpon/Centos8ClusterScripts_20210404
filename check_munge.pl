#!/usr/bin/perl
#munge setting for nodes developed by Prof. Shin-Pon Ju 2020/01/09
use strict;
use warnings;
use Expect;
use Parallel::ForkManager;

open my $ss,"< ./Server/Nodes_IP.dat" or die "No Nodes_IP.dat to read"; 
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

