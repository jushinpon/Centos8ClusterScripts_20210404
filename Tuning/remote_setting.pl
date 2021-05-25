#!/usr/bin/perl
use strict;
use warnings;

print "\n\n**** NFS setting\n";
my @nfs_server = qw(/mnt/Vdisk);
my @nfs_mount = qw(/master-Vdisk);#client machine path 
for (@nfs_){
	chomp;
	# need to exportfs -auv in server first
	system("umount -l master:$_"); # umount the nfs of master first
	system("rm -rf $_"); # umount the nfs of master first
	system("mkdir /master-$_"); # umount the nfs of master first
##the following is to remove all nfs disks
#`sed -i '/$_/d' /etc/fstab`;
#system("mount -a");
	
#	if(!`grep "$_" /etc/fstab`){
#		`echo master:/$_ /master-$_ nfs4 noacl,nocto,nosuid,noatime,nodiratime,_netdev,auto,bg,soft,rsize=32768,wsize=32768 0 0 >> /etc/fstab`;
#		system("mount -a");
#    }
#	else{
#		`sed -i '/$_/d' /etc/fstab`;
#		`echo master:/$_ /master-$_ nfs4 noacl,nocto,nosuid,noatime,nodiratime,_netdev,auto,bg,soft,rsize=32768,wsize=32768 0 0 >> /etc/fstab`;
#		system("mount -a");
#	}

}

system("hostname");
system("df -h");

