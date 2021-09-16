# ssh nodeXXX test
#nohup ifdown enp1s0 down && ifup enp1s0 up &

use Parallel::ForkManager;
$forkNo = 1;
my $pm = Parallel::ForkManager->new("$forkNo");

`rm -f diagonosis.dat`;
`touch diagonosis.dat`;
`touch scptest.dat`;
`dd if=/dev/zero of=scptest.dat bs=1024 count=10`;

for (1..42){
$pm->start and next;
    $nodeindex=sprintf("%02d",$_);
    $nodename= "node"."$nodeindex";
    $cmd = "ssh $nodename ";
    print "\n****Check $nodename status\n ";
    #`echo "***$nodename" >> diagonosis.dat`;
#ping test
    system("ping -c 1 $nodename");
    if($?){`echo "ping failed at $nodename" >> diagonosis.dat`;}

#scp test    
    system("scp -o ConnectTimeout=10 scptest.dat root\@$nodename:/root");
    if($?){`echo "scp failed at $nodename" >> diagonosis.dat`;}
#nfs test
    my @mount = `$cmd 'mount|grep nfs'`;
    chomp @mount;
    my @nfs = grep (($_=~m{master:/home|master:/opt}),@mount) ;
    unless(@nfs){`echo "nfs failed at $nodename" >> diagonosis.dat`;}   
   $pm->finish;
}
$pm->wait_all_children;
