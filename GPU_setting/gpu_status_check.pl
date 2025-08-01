use strict;
use warnings;
use Parallel::ForkManager;
use Cwd;
#my $currentPath = getcwd();
my $forkNo = 1;
my $pm = Parallel::ForkManager->new("$forkNo");
my %nodes = (
    161 => [1..42],#1,3,39..
    #161 => [18],#1,3,39..
    #161 => [22,30],#1,3,39..
    182 => [1..24],
    186 => [1..7],
    195 => [1..7],
    190 => [1..3],
    166 => [1..7]
    );

my $ip = `/usr/sbin/ip a`;    
$ip =~ /14\d\.1\d+\.\d+\.(\d+)/;
my $cluster = $1;
$cluster =~ s/^\s+|\s+$//;
#print "\$cluster: $cluster\n";
my @allnodes = @{$nodes{$cluster}};#get node information
   
#my @nodes1 = "";
`/usr/bin/touch ~/scptest.dat`;
my @allgpu;
my @badgpu;
my @errgpu;
my @no_dkms;
for (@allnodes){
#$pm->start and next;
    my $nodeindex=sprintf("%02d",$_);
    my $nodename= "node"."$nodeindex";
    my $cmd = "/usr/bin/ssh $nodename ";
    #print "****Check $nodename status\n ";
    #`echo "***$nodename" >> $output`;
    my @temp = `timeout 10 $cmd '/usr/sbin/lspci|/usr/bin/egrep "RTX 2080|RTX 3060|RTX 2060"'`;
    map { s/^\s+|\s+$//g; } @temp;

    if(@temp){
        print "\n\n$nodename has a gpu card:\n";
        push @allgpu,$nodename;
        my $dkms = `timeout 10 $cmd 'dkms status nvidia'`;
        $dkms =~ s/^\s+|\s+$//g;
        print "dkms status nvidia:$dkms\n";


        print "nvidia-smi:\n";
        my @temp1 = `timeout 10 $cmd 'nvidia-smi|grep Memory-Usage'`;
        #my @temperr = `timeout 10 $cmd 'nvidia-smi|grep Error'`;
        my @temp2 = `timeout 10 $cmd 'nvidia-smi|grep ERR'`;
        print "nvidia-smi done\n";

        map { s/^\s+|\s+$//g; } @temp1;
        map { s/^\s+|\s+$//g; } @temp2;
        
        unless(@temp1){push @badgpu,$nodename;}
        unless($dkms){push @no_dkms,$nodename;}
        if(@temp2){push @errgpu,$nodename;}

        #print "@temp\n";

    }

   #else{
   #     print "\n\n$nodename doesn't have a gpu card or gpu card is out of order:\n";
   #     print "$!,$@\n";
   # }
       
}

open(my $fh, '>', 'gpu_check.log') or die "Could not open file: $!";
print $fh "\n***All GPU: ".@allgpu."\n";
for (@allgpu){
    print $fh "$_\n";
}

print $fh "\n***Bad GPUs: ".@badgpu."\n";
for (@badgpu){
    print $fh "$_\n";
}
print "\n***ERR GPU: ". @errgpu. "\n";
for (@errgpu){
    print $fh "$_\n";
}
print $fh "\n***No dkms:".@no_dkms."\n";
for (@no_dkms){
    print $fh "$_\n";
}
close $fh;
print "Check gpu status done\n";
system("cat gpu_check.log");