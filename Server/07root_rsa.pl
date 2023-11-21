=b
This script helps to build the passwordless ssh longin to each node by root account. Developed by Prof. Shin-Pon Ju at NSYSY
2019/12/30

Nodes_IP.dat shows all node IPs (from 00initial_interfacesSetting.pl). you
may set new IPs for newly installed nodes. 
nutanix@cvm$ ping REMOTE_HOSTNAME -c 10 -M do -s 8972
ping REMOTE_HOSTNAME -f -l 8972
=cut
use strict;
use warnings;

use Expect;  
use Parallel::ForkManager;
use MCE::Shared;

my $newnodes = "yes"; # no for brand new installation, yes for adding new nodes into cluster

my $expectT = 10;# time peroid for expect

$ENV{TERM} = "vt100";
print "***Enter the password for nodes:\n";
my $pass = <STDIN>; ##For all roots of nodes
chomp $pass;
die "no passwd for nodes" unless($pass);
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
if ($newnodes eq "no"){
	system("rm -rf /root/\.ssh/*");# remove unexpect thing first
	system("mkdir /root/\.ssh");
	chdir("/root/.ssh");
	system("ssh-keygen -t rsa -N \"\" -f id_rsa");
	system("cp id_rsa.pub authorized_keys");
	system("chmod 700 /root/\.ssh");
	system("chmod 640 /root/\.ssh/authorized_keys");
	system("systemctl restart sshd");
}
#### make .ssh directory of each node
my $pm = Parallel::ForkManager->new("$forkNo");
for (@avaIP){	
$pm->start and next;
	my $exp = Expect->new;
	$exp = Expect->spawn("ssh -l root $_ \n");
	$exp->expect($expectT,[
						qr/password:/i,
						sub {
								my $self = shift ;
								$self->send("$pass\n");                            
								exp_continue;
							}
					],
					[
						qr/\/\[fingerprint\]\)\?/i,
						sub {
								my $self = shift ;
								$self->send("yes\n");	#first time to ssh into this node				        
								#Are you sure you want to continue connecting (yes/no)?
							}
					]
		); # end of exp 
	#the response after (yes/no)
	#Warning: Permanently added '192.168.0.2' (ECDSA) to the list of known hosts.
	#root@192.168.0.2's password:
				$exp->expect($expectT,[
						qr/password:/i,
						sub {
								my $self = shift ;
								$self->send("$pass\n");      
							}
					]);	
	
	$exp->send ("\n");
	$exp -> send("rm -rf /root/\.ssh\n") if ($exp->expect($expectT,'#'));
   	$exp -> send("mkdir  /root/\.ssh\n") if ($exp->expect($expectT,'#'));
    $exp -> send("chmod 700 /root/\.ssh\n") if ($exp->expect($expectT,'#'));
	$exp -> send("exit\n") if ($exp->expect($expectT,'#'));
	$exp->soft_close();
	#$exp->hard_close();
$pm->finish;
} # end of loop

$pm->wait_all_children;
# Beign scp
print "**********Beign scp\n";
sleep(1);
for (@avaIP){	
	$pm->start and next;
	my $exp = Expect->new;
	$exp = Expect->spawn("scp  /root/\.ssh/authorized_keys root\@$_:/root/\.ssh/ \n");
    $exp->expect($expectT,[
                    qr/password:/i,
                    sub {
                            my $self = shift ;
                            $self->send("$pass\n");     
                         }
                          ]
                 ); # end of exp     
	$exp->soft_close();
	#$exp->hard_close();
	$pm->finish;
}# for loop

$pm->wait_all_children;
sleep(1);
print "**********End scp\n";

#### change mode for 
print "**********Begin chmod\n";
for (@avaIP){	
	$pm->start and next;
	my $exp = Expect->new;
	$exp = Expect->spawn("ssh -l root $_ \n");
    $exp->expect($expectT,[
                    qr/password:/i,
                    sub {
                            my $self = shift ;
                            $self->send("$pass\n");     
                         }
                          ]
                 ); # end of exp 
	
    $exp -> send("\n");
    $exp -> send("chmod 640 /root/\.ssh/authorized_keys\n") if ($exp->expect($expectT,'#'));
   	$exp -> send("systemctl restart sshd \n") if ($exp->expect($expectT,'#'));
	$exp -> send("exit\n") if ($exp->expect($expectT,'#'));
	$exp->soft_close();
	#$exp->hard_close();
	$pm->finish;
}# for loop

$pm->wait_all_children;
print "**********End chmod\n";

######## go through each node for the final passworless setting

for (@avaIP){
	$pm->start and next;
	$_ =~/192.168.0.(\d{1,3})/;#192.168.0.X
	my $temp= $1 - 1;
    my $nodeindex=sprintf("%02d",$temp);
    my $nodename= "node"."$nodeindex";
    chomp $nodename;	
    print "**$_ $nodename**\n";
	my $exp = Expect->new;
	$exp = Expect->spawn("ssh $nodename \n");
	$exp->expect($expectT,
					[
						qr/connecting/i,
						sub {
								my $self = shift ;
								$self->send("yes\n");	#first time to ssh into this node				        
								#Are you sure you want to continue connecting (yes/no)?
							}
					]
		); # end of exp 				
	
	$exp->send ("\n") if ($exp->expect($expectT,'#'));
	$exp -> send("exit\n") if ($exp->expect($expectT,'#'));
	$exp->soft_close();
	#$exp->hard_close();
	$pm->finish;
} # end of loop
$pm->wait_all_children;

print "***** WATCH OUT!!!!!\n";
print "***** Begin  ssh passwordless test node by node!!!!!\n\n";
sleep(3);
for (@avaIP){	
	$pm->start and next;
	$_ =~/192.168.0.(\d{1,3})/;#192.168.0.X
	my $temp= $1 - 1;
    my $nodeindex=sprintf("%02d",$temp);
    my $nodename= "node"."$nodeindex";
    print "**nodename**:$nodename\n";
	system("ssh $nodename \"echo '$nodename done!'; exit\"");
	print "\n\n*****";
	$pm->finish;
}# for loop
$pm->wait_all_children;
print "\n\n***###05root_rsa.pl: root passwordless setting done******\n\n";
print "\n\n***IMPORTANT!!! Remove unsafe information in this script!!!!******\n\n";

