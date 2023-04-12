# lscpu --all --extended
#cat /proc/cpuinfo | grep "cpu MHz"

use warnings;
use strict;
use Parallel::ForkManager;
use Cwd;

my %nodes = (
    i9 => [6],
    i7 => [20..24]
);
my %disable = (
    i9 => [16..23],
    i7 => [16..19]

);
my @i9nodes = (6);#i9
my @i7nodes = (20..24);#17
my @i9Ecores = (16..23);#i9
my @i7Ecores = (16..19);
for my $cpu (keys %nodes){
    chomp $cpu;
    for my $node (@{$nodes{$cpu}}){
        my $nodeindex=sprintf("%02d",$node);
        my $nodename= "node"."$nodeindex";
        my $cmd = "ssh $nodename ";
        my @Ecores = @{$disable{$cpu}};
        my @allE;
        #echo 0 | sudo tee /sys/devices/system/cpu/cpu{NN}/online
        for my $ic (@Ecores){
            my $cpuid = "cpu$ic";
            #print "\$cpuid: $cpuid\n";
            push @allE,"\@reboot sleep 10 && echo 0 > /sys/devices/system/cpu/$cpuid/online"; 
            #system("$cmd \"echo 0 > /sys/devices/system/cpu/$cpuid/online\"");
        }
        chomp @allE;
        my $Ecores = join("\n",@allE);
#       crontab file here
        my $crontab = <<"END_MESSAGE";
PATH=/opt/anaconda3/bin:/opt/anaconda3/condabin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin
$Ecores
END_MESSAGE
        unlink "crontab_disableE";
        open(FH, '>',"crontab_disableE") or die $!;
        print FH $crontab;
        close(FH);
	    system("scp ./crontab_disableE root\@$nodename:/root");    
	    system("$cmd 'crontab ./crontab_disableE'"); 
        unlink "crontab_disableE";
    }
}
