=b
Perl script to mount all NSF folders from nodes.
You should export all folders in the nodes first.
=cut

#!/usr/bin/perl
use strict;
use warnings;
use Parallel::ForkManager;
my @nodes = 1..3;
my $forkNo = 10;
	
my %nfs = (# disks you want to share with server
	node01 => ["free","sdb"],
	node02 => ["free","sda"],
	node03 => ["free","sda"] 
	);
my $mount_setting = "nfs noacl,nocto,nosuid,noatime,nodiratime,".
					"_netdev,auto,bg,soft,rsize=32768,wsize=32768 0 0"; 	
#`echo master:/home /home nfs noacl,nocto,nosuid,noatime,nodiratime,_netdev,auto,bg,soft,rsize=32768,wsize=32768 0 0 >> /etc/fstab`;
	
my $nfs_dir = "/mnt/nodes_nfs";
system("mkdir -p $nfs_dir"); 
system("chmod -R 777 $nfs_dir"); 
for my $nodename (sort keys %nfs){
	chomp $nodename;
	print "***host: $nodename\n";
	system("mkdir -p /mnt/nodes_nfs/$nodename"); 

	for my $folder ( @{$nfs{$nodename}} ){
		print "folder: $folder\n";
		system("umount -l $nodename:/$folder"); 
		system("mkdir -p /mnt/nodes_nfs/$nodename/$folder");			
		`sed -i '/$nodename:\\/$folder/d' /etc/fstab`;
		`echo $nodename:/$folder /mnt/nodes_nfs/$nodename/$folder $mount_setting >> /etc/fstab`;		
	}	
}

`sed -i '/^\$/d' /etc/fstab`;
if(!`grep 'mount -a' /etc/rc.local`){
`echo mount -a >> /etc/rc.local`;}

if(!`grep 'setsebool -P use_nfs_home_dirs 1' /etc/rc.local`){
	`echo 'setsebool -P use_nfs_home_dirs 1' >> /etc/rc.local`;}
	
`setsebool -P use_nfs_home_dirs 1`;
system("mount -a");	
# end of nfs
