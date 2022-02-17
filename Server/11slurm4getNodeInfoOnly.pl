#!/usr/bin/perl
### for new nodes, you must modify IP_node
use warnings;
use strict;
use Expect;
use Parallel::ForkManager;
use MCE::Shared;
use Cwd; #Find Current Path

my $expectT = 10;# time peroid for expect

## get available IPs by reading or find them by ssh
open my $ss,"< ./Nodes_IP.dat" or die "No Nodes_IP.dat to read"; 
my @temp_array=<$ss>;
my @avaIP=grep (($_!~m{^\s*$|^#}),@temp_array); # remove blank lines and comment lines
close $ss; 
chomp @avaIP;
my $forkNo = 1;#@avaIP;
my $pm = Parallel::ForkManager->new("$forkNo");

tie my %coreNo, 'MCE::Shared';
tie my %socketNo, 'MCE::Shared';
tie my %threadcoreNo, 'MCE::Shared';
tie my %coresocketNo, 'MCE::Shared';
tie my %numaNo, 'MCE::Shared';

for (@avaIP){	
	$pm->start and next;
	my $exp = Expect->new;
	$exp = Expect->spawn("ssh -l root $_ \n");	
# get CPU Number	
	$exp->send ("lscpu|grep \"^CPU(s):\" | sed 's/^CPU(s): *//g' \n") if ($exp->expect($expectT,'#'));
	$exp->expect($expectT,'-re','\d+');#before() keeps command, match() keeps number, after() keep left part+root@master#
	my $Mread = $exp->match();
	chomp $Mread;
    if ($Mread){
	  $coreNo{$_} = $Mread;
	  print "coreNo hash array $_ , Mread: $Mread, $coreNo{$_}\n";
	  };
	  
# get socket Number	
	$exp->send ("lscpu|grep \"^Socket(s):\" | sed 's/^Socket(s): *//g' \n") if ($exp->expect($expectT,'#'));
	$exp->expect($expectT,'-re','\d+');#before() keeps command, match() keeps number, after() keep left part+root@master#
	$Mread = $exp->match();
	chomp $Mread;
    if ($Mread){
	  $socketNo{$_} = $Mread;
	  print "socketNo hash array $_ , Mread: $Mread, $socketNo{$_}\n";
	  };
 # get the thread Number per core 	
	$exp->send ("lscpu|grep \"^Thread(s) per core:\" | sed 's/^Thread(s) per core: *//g' \n") if ($exp->expect($expectT,'#'));
	$exp->expect($expectT,'-re','\d+');#before() keeps command, match() keeps number, after() keep left part+root@master#
	$Mread = $exp->match();
	chomp $Mread;
    if ($Mread){
	  $threadcoreNo{$_} = $Mread;
	  print "threadcoreNo hash array $_ , Mread: $Mread, $threadcoreNo{$_}\n";
	  };

# get the core Number per socket 	
	$exp->send ("lscpu|grep \"^Core(s) per socket:\" | sed 's/^Core(s) per socket: *//g' \n") if ($exp->expect($expectT,'#'));
	$exp->expect($expectT,'-re','\d+');#before() keeps command, match() keeps number, after() keep left part+root@master#
	$Mread = $exp->match();
	chomp $Mread;
    if ($Mread){
	  $coresocketNo{$_} = $Mread;
	  print "coresocketNo hash array $_ , Mread: $Mread, $coresocketNo{$_}\n";
	  };
# get the NUMA Number (slurm uses it as socket number)	
	$exp->send ("lscpu|grep \"^NUMA node(s):\" | sed 's/^NUMA node(s): *//g' \n") if ($exp->expect($expectT,'#'));
	$exp->expect($expectT,'-re','\d+');#before() keeps command, match() keeps number, after() keep left part+root@master#
	$Mread = $exp->match();
	chomp $Mread;
    if ($Mread){
	  $numaNo{$_} = $Mread;
	  print "numaNo hash array $_ , Mread: $Mread, $numaNo{$_}\n";
	  };
	  
	$exp -> send("exit\n") if ($exp->expect($expectT,'#'));
	$exp->soft_close();
	$pm->finish;
} # end of loop
$pm->wait_all_children;
sleep(1);

unlink "./IP_coreNo.txt";
open my $ss3,">./IP_coreNo.txt" or die "Can't open IP_coreNo.txt\n Reason:$!\n";
print $ss3 "IP  CoreNo SocketNo ThreadPerCore CorePerSocket NUMAnodeNo\n";

for (sort keys %coreNo){
    print $ss3 "$_  $coreNo{$_} $socketNo{$_} $threadcoreNo{$_} $coresocketNo{$_} $numaNo{$_}\n";
	print  "$_  $coreNo{$_} $socketNo{$_} $threadcoreNo{$_} $coresocketNo{$_} $numaNo{$_}\n";
	
}
close($ss3);
