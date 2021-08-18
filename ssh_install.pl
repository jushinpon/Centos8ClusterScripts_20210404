# ssh nodeXXX test
#nohup ifdown enp1s0 down && ifup enp1s0 up &

use Parallel::ForkManager;
$forkNo = 30;
my $pm = Parallel::ForkManager->new("$forkNo");
$reboot_check = "yes";

# status check
for (1..3){
$pm->start and next;

    $nodeindex=sprintf("%02d",$_);
    $nodename= "node"."$nodeindex";
    $cmd = "ssh $nodename ";
    print "\n****Check $nodename status\n ";
#restart nis    
   #system("$cmd 'systemctl restart rpcbind ypbind nis-domainname oddjobd'");#nis for nodes    
   #system("$cmd 'yptest'"); 
      
  #system("$cmd 'reboot'"); 
  #system("$cmd 'mount -a'"); 
     
# check disk for each nodes        
    #system("$cmd 'df -h'");    
    #system("$cmd 'blkid'");    
    #system("$cmd 'rpm -qa| grep parted'");
    #if not -> dnf install parted -y 
    #
    system("$cmd 'dnf install -y perl*'");    
    system("$cmd 'dnf install -y perl-Parallel-ForkManager'");    
    #system("$cmd 'chown -R jsp: /free'");    
$pm->finish;
}
$pm->wait_all_children;

die;


for (1..7){
    #$pm->start and next;
    $nodeindex=sprintf("%02d",$_);
    $nodename= "node"."$nodeindex";
    print "****nodename: $nodename\n";
    $cmd = "ssh $nodename ";
    ##infiniband driver, reboot is needed.
    #system("$cmd 'yum install -y ntfs-3g'");
    #system("$cmd 'systemctl restart rpcbind ypbind nis-domainname oddjobd'");#nis for nodes
    system("$cmd 'poweroff'");#nis for nodes
    print "\n****$nodename\n";
    system("$cmd 'df -h'|grep free");
    #my $temp = `$cmd 'df -h'|grep free`;
    #print "$temp\n";
    #if($temp =~ m{free}){print "$1\n"}
    #system("$cmd 'systemctl restart rpcbind ypbind nis-domainname oddjobd'");#nis for nodes
    #system("$cmd 'rm -f nohup.out;nohup perl ./06slurm_slave.pl &'");
    #system("$cmd 'dnf install -y iftop'");
    system("$cmd 'mount -a'");
    system("$cmd 'systemctl restart slurmd'");
    #system("$cmd 'dnf -y group install \"Development Tools\"'");
    
    # install progress
    #system("$cmd 'dnf install perl-Statistics-Descriptive -y;'");
    
    ##perl module
    
    #system("$cmd 'dnf install perl-Statistics-Descriptive -y'");
    #print "Check $nodename status\n ";
    #system("$cmd 'ibv_devinfo'");    
    #$pm->finish;
}
#$pm->wait_all_children;

die;
### check the node status after reboot
#if($reboot_check eq "yes"){
#	print "Sleep awhile (30 sec.) for checking reboot status\n";
#	sleep(30); 
#	for (1..3){
#		$nodeindex=sprintf("%02d",$_);
#		$nodename= "node"."$nodeindex";
#		system("ping -c 3 $nodename");
#		if($?){print "reboot for $nodename hasn't done!!\n\n"}	
#	}
#}

#for (1..41){
#    #$pm->start and next;
#    $nodeindex=sprintf("%02d",$_);
#    $nodename= "node"."$nodeindex";
#    #system("ssh $nodename 'dnf install perl-Statistics-Descriptive -y'");
#    print "nodename:$nodename\n";
#    system("munge -n \| ssh $nodename unmunge");
#    if($!){sleep(3);}
#    #$pm->finish;
#}
#$pm->wait_all_children;

