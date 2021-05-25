#!/usr/bin/perl
use strict;
use warnings;

print "\n\n**** NFS setting\n";
my $nfs_server = "/mnt/Vdisk";# server path
my $nfs_mount = "/master-Vdisk";#client machine path 
#for (@nfs_){
#	chomp;
# need to exportfs -auv in server first
system("umount -l master:$nfs_server"); # umount the nfs of master first
system("rm -rf $nfs_mount"); # umount the nfs of master first
system("mkdir $nfs_mount"); # umount the nfs of master first
##the following is to remove all nfs disks
#`sed -i '/$_/d' /etc/fstab`;
#system("mount -a");
	
if(!`grep "$nfs_server" /etc/fstab`){
	`echo master:$nfs_server $nfs_mount nfs4 noacl,nocto,nosuid,noatime,nodiratime,_netdev,auto,bg,soft,rsize=32768,wsize=32768 0 0 >> /etc/fstab`;
	system("mount -a");
   }
else{
	`sed -i '/$nfs_server/d' /etc/fstab`;
	## very tricky here for fsid=0
	`echo master:/ $nfs_mount nfs4 noacl,nocto,nosuid,noatime,nodiratime,_netdev,auto,bg,soft,rsize=32768,wsize=32768 0 0 >> /etc/fstab`;
	system("mount -a");
}

#}

system("hostname");
system("df -h");

