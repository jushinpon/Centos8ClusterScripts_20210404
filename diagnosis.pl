# ssh nodeXXX test
#nohup ifdown enp1s0 down && ifup enp1s0 up &

use Parallel::ForkManager;
$forkNo = 1;
my $pm = Parallel::ForkManager->new("$forkNo");
my $prefix = `date +\%F`;
chomp $prefix;
my $output = "$prefix"."_diagnosis.dat";
`rm -f $output`;
`touch $output`;
#`touch scptest.dat`;
#`dd if=/dev/zero of=scptest.dat bs=1024 count=10`;
#my 
#my @nodes;
for (1..42){

$pm->start and next;
    $nodeindex=sprintf("%02d",$_);
    $nodename= "node"."$nodeindex";
    $cmd = "ssh $nodename ";
    print "****Check $nodename status\n ";
    #`echo "***$nodename" >> $output`;
#ping test
    system("ping -c 1 $nodename");
    
    if($? ne 0){
        `echo "" >> $output`;
        `echo "??????ping failed at $nodename" >> $output`;
    }
    else{#ping ok
        `echo "" >> $output`;        
        `echo "******ping ok at $nodename" >> $output`;  
    #slurmd check
    my @slurmd = `$cmd 'systemctl status slurmd|grep inactive'`;
    if(@slurmd){
        `echo "???slurmd is inactive at $nodename" >> $output`;
        `echo "***doing restart slurmd at $nodename" >> $output`;        
        `$cmd 'systemctl restart slurmd'`;
        #check again
        @slurmd = `$cmd 'systemctl status slurmd|grep inactive'`;        
        if(@slurmd){`echo "???***slurmd still failed at $nodename after restart slurmd!!!!" >> $output`;}
    }
    else{
        `echo "slurmd is active at $nodename" >> $output`;
    }
    #chomp $nodename;
    #unless($?){system("$cmd 'systemctl restart slurmd'");}
#
    #system("scontrol update nodename=$nodename state=resume");

##scp test and remote cp test  
#    system("scp -o ConnectTimeout=10 scptest.dat root\@$nodename:/root");
#    if($?){`echo "scp failed at $nodename" >> $output`;}
#    system("$cmd 'cp scptest.dat /root/");
#    if($?){`echo "cp to root folder failed at $nodename" >> $output`;}
#
##nfs test
    my @mount = `$cmd 'mount|grep nfs'`;
    chomp @mount;
    my @nfs = grep (($_=~m{master:/home|master:/opt}),@mount) ;
    unless(@nfs){
        `echo "nfs failed at $nodename" >> $output`;
        `echo "doing mount -a at $nodename" >> $output`;        
        `$cmd 'mount -a'`;
        #check again
        @mount = `$cmd 'mount|grep nfs'`;
        @nfs = grep (($_=~m{master:/home|master:/opt}),@mount);        
        unless(@nfs){`echo "???***nfs still failed at $nodename after mount -a!!!!" >> $output`;}
        
    }
    else{
        `echo "nfs good at $nodename" >> $output`;
    }
##munge test
    system("munge -n \| ssh $nodename unmunge");
    if($?){`echo "munge failed at $nodename" >> $output`;} 
    }# good ping loop 
   $pm->finish;
}
$pm->wait_all_children;
