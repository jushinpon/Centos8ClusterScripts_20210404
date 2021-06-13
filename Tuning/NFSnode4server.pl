#!/usr/bin/perl
use strict;
use warnings;
## make NFS client (slave node)
#!/usr/bin/perl
#setsebool -P use_nfs_home_dirs boolean 1
#To verify that the setting has been changed, execute the following:
#getsebool use_nfs_home_dirs boolean
#If enabled, the output should be the following:
#use_nfs_home_dirs --> on
use strict;
use warnings;

my %nfs = (# disks you want to share with server
	node01 => ["free","sdb"],#8G,/free:888G,/sdb:931Gib
	node02 => ["free","sda"],#16G,/free:878G,/sda:1.7T 
	node03 => ["free","sda"] #16G,/free:878G,/sda:870G
	);
my $hostname = `hostname`;
chomp $hostname;
system("rm -f /etc/exports");
system("touch /etc/exports");
for ( @{$nfs{$hostname}} ){
	`chmod -R 777 /$_`;
	`echo "/$_ 192.168.0.0/24(rw,no_root_squash,no_subtree_check,async)" >> /etc/exports`;
}

`systemctl enable nfs-server`;
`systemctl start nfs-server`;
system("exportfs -auv"); # umount all first if you have mounted some previously!
system("exportfs -arv"); # make setting work!


#
#system("perl -p -i.bak -e 's/master:.+//g;' /etc/fstab");# remove old setting lines
#
#`echo master:/home /home nfs4 noacl,nocto,nosuid,noatime,nodiratime,_netdev,auto,bg,soft,rsize=32768,wsize=32768 0 0 >> /etc/fstab`;
#`echo master:/opt /opt nfs4 noacl,nocto,nosuid,noatime,nodiratime,_netdev,auto,bg,soft,rsize=32768,wsize=32768 0 0 >> /etc/fstab`;
#
#if(!`grep 'mount -a' /etc/rc.local`){
#	`echo mount -a >> /etc/rc.local`;}
#	
#if(!`grep 'setsebool -P use_nfs_home_dirs 1' /etc/rc.local`){
#	`echo 'setsebool -P use_nfs_home_dirs 1' >> /etc/rc.local`;}
#	
#`setsebool -P use_nfs_home_dirs 1`;
#system("mount -a");
#
#
#
#
#
#my @nodeID = (1..1);
#
#my $forkNo = @nodeID;
#
#if(! -d "/freespace"){`mkdir /freespace`;`chown -R jsp /freespace`;}
#if(! `grep "/freespace" /etc/exports`){`echo "/freespace 192.168.0.0/24(rw,no_root_squash,no_subtree_check,async)" >> /etc/exports`;}
#
#`systemctl restart nfs-server`;#`systemctl start nfs` the same
#
#system("exportfs -auv"); # umount all first if you have mounted some previously!
#system("exportfs -arv"); # make setting work!
#
## mount|grep nfs
## rpcinfo -t localhost nfs
## -v list all shared folders
##-a
## exportfs  -s : check all exported information
##showmount -e
################ node setting 
#my $pm = Parallel::ForkManager->new("$forkNo");
#for (1..3){
#    $pm->start and next;
#    $nodeindex=sprintf("%02d",$_);
#    $nodename= "node"."$nodeindex";
#    $cmd = "ssh $nodename ";
#    
#    ##infiniband driver, reboot is needed.
#    #system("$cmd 'yum install -y libibverbs libibverbs-utils infiniband-diags perftest'");
#    system("$cmd 'dnf install -y iftop'");
#    #system("$cmd 'poweroff'");
#    
#    ##perl module
#    #system("$cmd 'dnf install perl-Statistics-Descriptive -y'");
#    #print "Check $nodename status\n ";
#    #system("$cmd 'ibv_devinfo'");    
#    $pm->finish;
#}
#$pm->wait_all_children;
#
#
#
