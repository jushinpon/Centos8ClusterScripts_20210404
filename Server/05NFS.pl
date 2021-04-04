#!/usr/bin/perl
=b
The configuration files for the NFS server for Centos 8 are:

/etc/nfs.conf  main configuration file for the NFS daemons and tools.
/etc/nfsmount.conf  an NFS mount configuration file.

https://www.tecmint.com/install-nfs-server-on-centos-8/
Note that the other services that are required for running an NFS server
or mounting NFS shares such as nfsd, nfs-idmapd, rpcbind, rpc.mountd, lockd,
rpc.statd, rpc.rquotad, and rpc.idmapd will be automatically started.

=cut
use strict;
use warnings;

#system("perl -p -i.bak -e 's/.+RPCNFSDCOUNT.+/RPCNFSDCOUNT=128/;' /etc/sysconfig/nfs");
#system("systemctl start nfs-server");
############### NFS share Folder ###################
#system("mkdir /work");
`chmod -R 755 /home`;
`chmod -R 755 /opt`;

############### exports file setting ###################
#/home
`echo "/home 192.168.0.0/24(rw,no_root_squash,no_subtree_check,async)" > /etc/exports`;
#/opt
`echo "/opt 192.168.0.0/24(rw,no_root_squash,no_subtree_check,async)" >> /etc/exports`;

#`systemctl enable rpcbind`;
`systemctl enable nfs-server`;#systemctl enable nfs`  the same
#`systemctl enable nfs-lock`;#to avoid race conditions 
#`systemctl enable nfs-idmap`;

#`systemctl start rpcbind`;
`systemctl start nfs-server`;#`systemctl start nfs` the same
#`systemctl start nfs-lock`;
#`systemctl start nfs-idmap`;

system("exportfs -auv"); # umount all first if you have mounted some previously!
system("exportfs -arv"); # make setting work!
print "\n\n***###03NFS.pl: set NFS done******\n\n";
# mount|grep nfs
# rpcinfo -t localhost nfs
# for internal?
# firewall-cmd --permanent --add-service=nfs
# firewall-cmd --permanent --add-service=rpc-bind
# firewall-cmd --permanent --add-service=mountd
# firewall-cmd --reload

# -v list all shared folders
#-a
# exportfs  -s : check all exported information
#showmount -e
########################## 
