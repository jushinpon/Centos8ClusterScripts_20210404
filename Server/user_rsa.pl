=b
This script helps to build the passwordless ssh longin to each node by root account. Developed by Prof. Shin-Pon Ju at NSYSY
2019/12/30

Nodes_IP.dat shows all node IPs (from 00initial_interfacesSetting.pl). you
may set new IPs for newly installed nodes. 
nutanix@cvm$ ping REMOTE_HOSTNAME -c 10 -M do -s 8972
ping REMOTE_HOSTNAME -f -l 8972
setsebool -P use_nfs_home_dirs 1  for each node by root 
*****NIS and NFS should be workable in advance.
=cut
use strict;
use warnings;

use Expect;  
use Parallel::ForkManager;
use MCE::Shared;
my $expectT = 5;# time peroid for expect

$ENV{TERM} = "vt100";
my $pass = ""; ##For all roots of nodes
my $user = "";

open my $ss,"< ./Nodes_IP.dat" or die "No Nodes_IP.dat to read"; 
my @temp_array=<$ss>;
my @avaIP=grep (($_!~m{^\s*$|^#}),@temp_array); # remove blank lines and comment lines
close $ss; 

for (@avaIP){
	$_  =~ s/^\s+|\s+$//;
	chomp;
	print "IP: $_\n";
}
#my $forkNo = @avaIP;
my $forkNo = 1;
print "forkNo: $forkNo\n";

my $exp = Expect->new;
$exp = Expect->spawn("su $user \n");
$exp -> send("rm -rf /home/$user/\.ssh\n") if ($exp->expect($expectT,"$user"));
$exp -> send("mkdir /home/$user/\.ssh\n") if ($exp->expect($expectT,"$user"));

$exp -> send("cd /home/$user/\.ssh\n") if ($exp->expect($expectT,"$user"));
$exp -> send("ssh-keygen -t rsa -N \"\" -f id_rsa\n") if ($exp->expect($expectT,"$user"));
$exp -> send("cp id_rsa.pub authorized_keys\n") if ($exp->expect($expectT,"$user"));
$exp -> send("chmod 740 /home/$user/\.ssh\n") if ($exp->expect($expectT,"$user"));
$exp -> send("chmod 640 /home/$user/\.ssh/authorized_keys\n") if ($exp->expect($expectT,"$user"));
$exp -> send("chmod 640 /home/$user/\.ssh/id_rsa.pub\n") if ($exp->expect($expectT,"$user"));
$exp -> send("exit\n") if ($exp->expect($expectT,"$user"));#back to root
$exp->soft_close();

#### make .ssh directory of each node

my $pm = Parallel::ForkManager->new("$forkNo");

# Beign scp
for (@avaIP){	
	$pm->start and next;
	chomp;
	my $exp = Expect->new;
	$exp = Expect->spawn("su $user \n");
	$exp -> send("ssh $_\n") if ($exp->expect($expectT,"$user"));
    $exp->expect($expectT,					[
						qr/\/\[fingerprint\]\)\?/i,
						sub {
								my $self = shift ;
								$self->send("yes\n");	#first time to ssh into this node				        
								#Are you sure you want to continue connecting (yes/no)?
								exp_continue;
							}
					],
					[
                    qr/password:/i,
                    sub {
                            my $self = shift ;
                            $self->send("$pass\n");     
                         }
                          ]
                 ); # end of exp	
   $exp -> send("exit\n") if ($exp->expect($expectT,"$user"));#back to user@master
   $exp -> send("exit\n") if ($exp->expect($expectT,"$user"));#back to root@master

   $exp->soft_close();
	#$exp->hard_close();
	$pm->finish;
}# for loop

$pm->wait_all_children;

## go through nodename fingerprint again

for (@avaIP){	
	$pm->start and next;
	chomp;
	$_ =~/192.168.0.(\d{1,3})/;#192.168.0.X
	my $temp= $1 - 1;
    my $nodeindex=sprintf("%02d",$temp);
    my $nodename= "node"."$nodeindex";
    chomp $nodename;
    print "**nodename**:$nodename\n";
	my $exp = Expect->new;
	$exp = Expect->spawn("su $user \n");
	$exp -> send("ssh $nodename\n") if ($exp->expect($expectT,"$user"));
    $exp->expect($expectT,					[
						qr/\/\[fingerprint\]\)\?/i,
						sub {
								my $self = shift ;
								$self->send("yes\n");	#first time to ssh into this node				        
								#Are you sure you want to continue connecting (yes/no)?
							}
					]
                 ); # end of exp
$exp->expect($expectT,					
					[
                    qr/password:/i,
                    sub {
                            my $self = shift ;
                            $self->send("$pass\n");     
                         }
                          ]
                 ); # end of exp  
                 
                 
                
                 	
   $exp -> send("exit\n") if ($exp->expect($expectT,"$user"));#back to user@master
   $exp -> send("exit\n") if ($exp->expect($expectT,"$user"));#back to root@master

   $exp->soft_close();
	#$exp->hard_close();
	$pm->finish;
}# for loop

$pm->wait_all_children;
sleep(1);

print "***** WATCH OUT!!!!!\n";
print "***** Begin  ssh passwordless test node by node!!!!!\n\n";
sleep(3);
for (@avaIP){	
	#$pm->start and next;
	$_ =~/192.168.0.(\d{1,3})/;#192.168.0.X
	my $temp= $1 - 1;
    my $nodeindex=sprintf("%02d",$temp);
    my $nodename= "node"."$nodeindex";
    chomp $nodename;
    print "**nodename**:$nodename\n";
    my $exp = Expect->new;
	$exp = Expect->spawn("su $user \n");
	$exp -> send("ssh $nodename\n") if ($exp->expect($expectT,"$user"));
	$exp -> send("exit\n") if ($exp->expect($expectT,"$user"));#back to user@master
    $exp -> send("exit\n") if ($exp->expect($expectT,"$user"));#back to root@master
	$exp->soft_close();
	print "\n\n*****";
	#$pm->finish;
}# for loop
print "\n\n***###user_rsa.pl: user passwordless setting done******\n\n";

print "\n\n***IMPORTANT!!! Remove unsafe information in this script!!!!******\n\n";
