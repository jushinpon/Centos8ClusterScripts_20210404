=b
sudo yum install smartmontools -y
sudo smartctl -a /dev/sdX

Run a SMART Self-test
sudo smartctl -t short /dev/sdX
check test results:
sudo smartctl -a /dev/sdX:
SMART Self-test log structure revision number 1
Num  Test_Description    Status                  Remaining  LifeTime(hours)  LBA_of_first_error
# 1  Short offline       Completed without error       00%     23601         -

Run a badblocks check to see if there are any bad sectors on the disk:
badblocks -v /dev/sdX1

If bad blocks are found, you can run fsck with the -c option to mark these blocks as bad:

bash
Copy code
sudo fsck -c /dev/sdX1

fsck -f /dev/sdX1
=cut


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

