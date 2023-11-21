=b
/opt/nvidia/hpc_sdk/Linux_x86_64/23.7/compilers/bin/nvaccelinfo

$ nvaccelinfo | grep -e 'Target' -e 'Driver'
CUDA Driver Version:           11000
Default Target:                cc70
=cut

use warnings;
use strict;
use Expect;
use Parallel::ForkManager;
use Cwd; #Find Current Path

open my $ss,"> AllGPU_info.dat";

my $nvaccelinfo = '/opt/nvidia/hpc_sdk/Linux_x86_64/23.7/compilers/bin/nvaccelinfo \\
| grep -e "Target" -e "Driver" -e "Global Memory Size"';
my $lspci = 'lspci|grep NV';

my $lspci_check = "yes";
my $nvacc_check = "yes";
my %nodes = (
    161 => [1..42],#1,3,39..
    #182 => [1..4,6..15,17..24],
    182 => [1..24],
    #186 => [1..7],
    #190 => [1..3]
    );

my $ip = `/usr/sbin/ip a`;    
$ip =~ /140\.117\.\d+\.(\d+)/;
my $cluster = $1;
$cluster =~ s/^\s+|\s+$//;
#print "\$cluster: $cluster\n";
my @allnodes = @{$nodes{$cluster}};#all possible nodes including those without service
my @nodes;
my @nodeIPs;
for (@allnodes){#filtering the good ones
#$pm->start and next;
    my $nodeindex=sprintf("%02d",$_);
    my $nodename= "node"."$nodeindex";
    print "****Check $nodename status\n ";
    #`echo "***$nodename" >> $output`;
#use scp for ssh test
	system("scp -o ConnectTimeout=5 ./scptest.dat root\@$nodename:/root");    
    
    if($?){
		print "scp at $nodename failed\n";
        `echo "$nodename is currently dead." >> ./slurmdDead.txt`;

		next;
	}
	else{
		print "scp at $nodename ok for ssh test\n";
        push @nodes,$_;#keep node number
	}	
}    

for (@nodes){
    my $nodeindex=sprintf("%02d",$_);
    my $nodename= "node"."$nodeindex";
    my $cmd = "ssh $nodename ";

    if($lspci_check eq "yes"){      
        my @temp = `$cmd '$lspci'`;
        map { s/^\s+|\s+$//g; } @temp;
        my $temp = join("\n", @temp);
        #print "$temp\n";
        if($temp =~ /\[(.+K.+)\]/ or $temp =~ /\[(.+\d{4,4}.+)\]/){
        #if($temp =~ /\[(.+\d{4,4}.+)\]|\[(.+K.+)\]/){
            $1 =~ s/^\s+|\s+$//g;
            print $ss "$nodename:\n$1\n";
        }
    }

    if($nvacc_check eq "yes"){      
        my @temp = `$cmd '$nvaccelinfo'`;
        map { s/^\s+|\s+$//g; } @temp;
        my $temp = join("\n", @temp);
        #print "\$temp: $temp\n";
        if($temp){
            print $ss "$temp\n\n";
        }
    }

    
    #    print "\$temp: $temp, $nodename failed\n";
    #    `$cmd 'systemctl restart slurmd'`;
    #    system("$cmd 'systemctl enable slurmd'");
#
    #    `scontrol update nodename=$nodename state=resume`;
    #    #sinfo|grep All|grep down|awk '{print $NF}'
    #}
    #else{
    #    print "\$temp: $temp,$nodename ok\n";
    #}    
}
close($ss);
print "ALL DONE!\n";

