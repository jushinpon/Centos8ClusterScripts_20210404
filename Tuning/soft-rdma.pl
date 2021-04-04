=beg
Modify the memlock in /etc/security/limits.conf for master and each node 
soft-roce configuration below:
https://community.mellanox.com/s/article/howto-configure-soft-roce
Nodes_IP.dat is required
=cut
#!/usr/bin/perl
use strict;
use warnings;
use Expect;
use Cwd; #Find Current Path
use Parallel::ForkManager;
#use MCE::Shared;

### soft-roce for master
system





#Reading required information for node 
open my $ss,"< ../Server/Server_setting.dat" or die "No Server_setting.dat to open.\n $!";
my @temp_array = <$ss>;
close $ss; 

my @temp_array1=grep (($_!~m{^\s*$|^#}),@temp_array); # remove blank lines
my %ServerSetting; # keep all information for Server setting
for (@temp_array1){
	$_  =~ s/^\s+|\s+$//;
	my @temp = split (/=/,$_) ;
	$temp[0]  =~ s/^\s+|\s+$//;
	chomp ($temp[0]);
	$temp[1]  =~ s/^\s+|\s+$//;
	chomp ($temp[1]);
	$ServerSetting{$temp[0]} = $temp[1] ;
}

#get internet card name
my $temp = `ip a|grep "state UP"`;
my @temp = split "\n", $temp;
my @temp1 = grep (($_!~m{^\s*$}),@temp); # remove blank lines
my $upStateNo = @temp1;
if ($upStateNo > 1){die "The Number \($upStateNo\) of up state NIC is more than one!!\n";}
$temp1[0] =~ m{:\s+(.+)\s*:};
chomp $1;
print "NIC: $1\n";
if ($1 eq ""){die "No NIC exits\n";}

my $Nic_inner = $1;
`ip a`=~ m{192.168.0.(\d{1,3})\/24};
my $fourthdigital = $1;
my $nodeID = $fourthdigital - 1;# node ID according to th fourth number of current IP
# get MAC of each internet card
my %mac;
my $ipne = `ip add show $Nic_inner`;      
$ipne =~ /(\w+:\w+:\w+:\w+:\w+:\w+)/;# the first matched item is mac!
$mac{$Nic_inner}="$1";      
$nodeID =~ s/^\s+|\s+$//;
chomp($nodeID);
my $formatted_nodeID = sprintf("%02d",$nodeID);
my $hostname="node"."$formatted_nodeID";


#****$jobtype = "nohup" or "copy"
my $jobtype = "nohup";# nohup perl for node scripts, otherwise copy files only

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

if(!`grep '* soft memlock unlimited' /etc/security/limits.conf`){
	`echo '* soft memlock unlimited' >> /etc/security/limits.conf`;
}
if(!`grep '* hard memlock unlimited' /etc/security/limits.conf`){
	`echo '* hard memlock unlimited' >> /etc/security/limits.conf`;
}

