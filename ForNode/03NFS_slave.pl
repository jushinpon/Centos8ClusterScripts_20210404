## make NFS client (slave node)
#!/usr/bin/perl
#setsebool -P use_nfs_home_dirs boolean 1
#To verify that the setting has been changed, execute the following:
#getsebool use_nfs_home_dirs boolean
#If enabled, the output should be the following:
#use_nfs_home_dirs --> on
use strict;
use warnings;

print "\n\n**** NFS setting\n";
system("umount -l master:/home"); # umount the nfs of master first
system("umount -l master:/opt"); # umount the nfs of master first
`systemctl enable rpcbind`;
#`systemctl enable nfs-lock`;#to avoid race conditions,the same setting as the server's 
`systemctl start rpcbind`;
#`systemctl start nfs-lock`;

system("perl -p -i.bak -e 's/master:.+//g;' /etc/fstab");# remove old setting lines

`echo master:/home /home nfs noacl,nocto,nosuid,noatime,nodiratime,_netdev,auto,bg,soft,rsize=32768,wsize=32768 0 0 >> /etc/fstab`;
`echo master:/opt /opt nfs noacl,nocto,nosuid,noatime,nodiratime,_netdev,auto,bg,soft,rsize=32768,wsize=32768 0 0 >> /etc/fstab`;

if(!`grep 'mount -a' /etc/rc.local`){
	`echo mount -a >> /etc/rc.local`;}
	
if(!`grep 'setsebool -P use_nfs_home_dirs 1' /etc/rc.local`){
	`echo 'setsebool -P use_nfs_home_dirs 1' >> /etc/rc.local`;}
	
`setsebool -P use_nfs_home_dirs 1`;
system("mount -a");
