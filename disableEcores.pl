# lscpu --all --extended
use warnings;
use strict;
use Parallel::ForkManager;
use Cwd;
my @nodes = (6);
my @Ecores = (16..23);
for (@nodes){
    my $nodeindex=sprintf("%02d",$_);
    my $nodename= "node"."$nodeindex";
    my $cmd = "ssh $nodename ";
    #echo 0 | sudo tee /sys/devices/system/cpu/cpu{NN}/online
    for my $ic (@Ecores){
        my $cpuid = "cpu$ic";
        print "\$cpuid: $cpuid\n";
        system("$cmd \"echo 0 > /sys/devices/system/cpu/cpu$ic/online\"");
    }
}
