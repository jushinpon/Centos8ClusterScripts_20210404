=beg
This Perl script uses the Expect module to scp all required Perl scripts from server to each node after you assign the private IP
for all nodes. We put all scripts in the directory "ForNode".-- developed by Prof. Shin-Pon Ju at NSYSU (11/28/2019)

./Server/Server_setting.dat should be copied to each node for the following setting. (scp..) 
Nodes_IP.dat: from 00initial_interfacesSetting.pl
=cut
#!/usr/bin/perl
use strict;
use warnings;
use Expect;
use Cwd; #Find Current Path
use Parallel::ForkManager;
use MCE::Shared;
#****$jobtype = "nohup" or "copy"
my $jobtype = "nohup";# nohup perl for node scripts, otherwise copy files only

## set unlimited ram memory
if(!`grep '* soft memlock unlimited' /etc/security/limits.conf`){
	`echo '* soft memlock unlimited' >> /etc/security/limits.conf`;
}
if(!`grep '* hard memlock unlimited' /etc/security/limits.conf`){
	`echo '* hard memlock unlimited' >> /etc/security/limits.conf`;
}

# "ssh nodeXX 'ls /root/*.pl'` to check whether scp works, currently 9 files
tie my @scpFailnodes, 'MCE::Shared';
tie my %scpstatus, 'MCE::Shared';# good, or failed
my $current_path = getcwd();# get the current path dir

#print "****current_path: $current_path $current_path1\n";
#sleep(100);
$current_path =~ s/\/Server//;# get the path for node scripts (ForNode)

my $expectT = 30;# time peroid for expect

$ENV{TERM} = "vt100";
my $pass = "123"; ##For all roots of nodes

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
#my $forkNo = 30;
my $pm = Parallel::ForkManager->new("$forkNo");

for (@avaIP){	
   sleep(3);
	$pm->start and next;
	$_ =~/192.168.0.(\d{1,3})/;#192.168.0.X
	my $temp= $1 - 1;
    my $nodeindex=sprintf("%02d",$temp);
    my $nodename= "node"."$nodeindex";
    chomp $nodename;
    unlink "/home/$nodename.txt";
    
    print "**nodename**:$nodename\n";
    system("ssh $nodename \'rm -rf /root/*.pl\'");
 if ($?){print "BAD: ssh $nodename \'rm -f /root/*.pl\' failed\n";};    
    system("ssh $nodename \'rm -rf /root/*.txt\'");
 if ($?){print "BAD: ssh $nodename \'rm -rf /root/*.txt\' failed\n";};    
    sleep(1);
    system("scp  $current_path/ForNode/* root\@$nodename:/root");
 if ($?){print "BAD: scp  $current_path/ForNode/* root\@$nodename:/root failed\n";};    
    sleep(1);	
    system("scp  $current_path/Server/Server_setting.dat root\@$nodename:/root");
 if ($?){print "BAD: scp  /Server/Server_setting.dat root\@$nodename:/root failed\n";};    
my @ls = `ssh $nodename 'ls /root/{*.pl,Server_setting.dat}'`;
#for (@ls) {chomp;print "ls: $_ \n";}
my $lsno = @ls;
chomp $lsno;
#print "ls number: $lsno\n";
if($lsno == 9){
	chomp $nodename;
	$scpstatus{$nodename} = "good";
}
else{
   chomp $nodename;
   $scpstatus{$nodename} = "failed";
   push @scpFailnodes,$nodename;
}
 print "***scpstatus: $scpstatus{$nodename}\n";
	system("ssh $nodename \'rm -rf nohup.out\'");
 if ($?){print "BAD: ssh $nodename \'rm -rf nohup.out\' failed\n";};    
    sleep(1);
    if ($jobtype eq "nohup" and $scpstatus{$nodename} eq "good"){
		my $exp = Expect->new;
		$exp = Expect->spawn("ssh $nodename");
		$exp->send ("nohup perl oneclick_slave.pl & \n") if ($exp->expect($expectT,'#'));# nohup perl can't be done by ssh nodeXX ''
		$exp -> send("\n") if ($exp->expect($expectT,'#'));
		$exp -> send("rm -f oneclick_start.dat\n") if ($exp->expect($expectT,'#'));
		$exp -> send("echo \'oneclick_start'\ > oneclick_start.dat\n") if ($exp->expect($expectT,'#'));
		$exp -> send("ps aux|grep oneclick_slave.pl >> oneclick_start.dat\n") if ($exp->expect($expectT,'#'));
		$exp -> send("\n") if ($exp->expect($expectT,'#'));
		$exp -> send("exit\n") if ($exp->expect($expectT,'#'));
		$exp->soft_close();
    }
    $pm-> finish;
}# for loop
$pm->wait_all_children;

print "\n\n****The following is to show nodes with failed scp process or all good!!!\n\n";
if(@scpFailnodes){
	for (@scpFailnodes){
		chomp;
		print "$_ scp process failed!!!\n";
	}
}
else{
	print "scp for all nodes are ok!!\n\n\n";
}
sleep(3);
## check node setting status of each node
my $nodeNo = @avaIP - @scpFailnodes;
my $totnode = @avaIP;
my $badscpnode = @scpFailnodes;
my $whileCounter = 0;
my $Counter = 100;
while ($whileCounter <= 100 and $Counter != $nodeNo and $jobtype eq "nohup"){
	$whileCounter += 1;
	$Counter = 0;

	for (@avaIP){	
		$_ =~/192.168.0.(\d{1,3})/;#192.168.0.X
		my $temp= $1 - 1;
		my $nodeindex=sprintf("%02d",$temp);
		my $nodename= "node"."$nodeindex";
		print "**nodename and scpstatus**:$nodename,$scpstatus{$nodename}\n";
		if ($scpstatus{$nodename} eq "good"){
			if( -e "/home/$nodename.txt"){
				$Counter += 1;			
				print "$nodename: setting Done!!!\n";
			}
			else{
				print "$nodename: setting hasn't done\n";
			}
		}		 
	}
	print "\n\n****Doing while times: $whileCounter\n";
	print "total available node number: $totnode\n";
	print "bad scp node number: $badscpnode\n";
	print "total node number need to do the setting: $nodeNo\n";
	print "Current node number with setting done: $Counter\n\n";
	sleep(20);
}
## check whether setting status of each node is OK
if($jobtype eq "nohup"){ 
	print "Watch out! Check whether each node has been correctly deployed!\n\n";
	for (@avaIP){	
		$_ =~/192.168.0.(\d{1,3})/;#192.168.0.X
		my $temp= $1 - 1;
		my $nodeindex=sprintf("%02d",$temp);
		my $nodename= "node"."$nodeindex";
		$temp = `cat /home/$nodename.txt`;
		if($temp =~ m{(ALL DONE!!)}){
			chomp $1;
			print "$nodename: $1\n";
		}
		else{
			print "***$nodename setting has problems. See /home/$nodename.txt\n";
		}			 
	}
}
print "\n\n****Final reminding: the following shows nodes with scp failed or all good!!!\n\n";
if(@scpFailnodes){
	for (@scpFailnodes){
		chomp;
		print "$_ scp process failed!!!\n";
	}
}
else{
	print "scp for all nodes are ok!!\n";
}
