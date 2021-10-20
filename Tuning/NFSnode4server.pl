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

#my %nfs = (# disks you want to share with server
#	node01 => ["free","sdb","sdc","sdd"],
#	node02 => ["free","sda","sdc","sdd"], 
#	node03 => ["free","sda","sdc"] 
#	);
my @nodes = (1..27,32..42);
my %nfs;
for (@nodes){
    my $nodeindex = sprintf("%02d",$_);
    my $nodename = "node"."$nodeindex";
	$nfs{$nodename} = ["free"];
}
my $hostname = `hostname`;
chomp $hostname;
system("rm -f /etc/exports");
system("touch /etc/exports");
for my $folder ( @{$nfs{$hostname}} ){
	#`chmod -R 777 /$_`;
	chomp $folder;
	if($folder eq "free"){
		`echo "/$folder 192.168.0.0/24(rw,no_root_squash,no_subtree_check,async)" >> /etc/exports`;
	}
	else{
		`echo "/mnt/$folder 192.168.0.0/24(rw,no_root_squash,no_subtree_check,async)" >> /etc/exports`;
	}
}

`systemctl enable nfs-server`;
`systemctl start nfs-server`;
system("exportfs -auv"); # umount all first if you have mounted some previously!
system("exportfs -arv"); # make setting work!
