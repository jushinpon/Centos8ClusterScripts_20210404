#!/usr/bin/perl
use strict;
use warnings;

print "\n\n**** NFS setting\n";
my @nfs = qw(sdb);
for (@nfs){
	chomp;
	system("umount -l master:/master-$_"); # umount the nfs of master first
	system("rm -rf /master-$_"); # umount the nfs of master first
	system("mkdir /master-$_"); # umount the nfs of master first
	
	if(!`grep "$_" /etc/fstab`){
		`echo master:/$_ /master-$_ nfs4 noacl,nocto,nosuid,noatime,nodiratime,_netdev,auto,bg,soft,rsize=32768,wsize=32768 0 0 >> /etc/fstab`;
		system("mount -a");
    }
	else{
		`sed -i '/$_/d' /etc/fstab`;
		`echo master:/$_ /master-$_ nfs4 noacl,nocto,nosuid,noatime,nodiratime,_netdev,auto,bg,soft,rsize=32768,wsize=32768 0 0 >> /etc/fstab`;
		system("mount -a");
	}

}

system("hostnmae");
system("df -h");

