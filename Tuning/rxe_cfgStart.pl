# start soft-RoCE when rebooting
use strict;
use warnings;
# for master
system("rxe_cfg stop");	
system("rxe_cfg start");
print "\n";
#for nodes
for (1..2){
    my $nodeindex=sprintf("%02d",$_);
    my $nodename= "node"."$nodeindex";
    chomp $nodename;	
    print "**Doing rxe_cfg start for $nodename\n\n";
    system("ssh $nodename rxe_cfg stop");	
    system("ssh $nodename rxe_cfg start");	
    print "\n\n";
	sleep(3);
}
