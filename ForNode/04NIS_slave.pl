## You Need install ypbind yp-tools ypserv rpcbind first
## yum -y install ypbind yp-tools ypserv rpcbind 
#!/usr/bin/perl
use strict;
use warnings;

`ypdomainname melcluster`;
`echo "NISDOMAIN=melcluster" > /etc/sysconfig/network`;
`echo "domain melcluster server master" > /etc/yp.conf`;
system("authselect select nis --force");
system("authselect enable-feature with-mkhomedir");
`setsebool -P nis_enabled on`;
system("systemctl start rpcbind ypbind nis-domainname oddjobd");
system("systemctl enable rpcbind ypbind nis-domainname oddjobd");
system("systemctl restart rpcbind ypbind nis-domainname oddjobd");
#`setsebool -P use_nfs_home_dirs 1`;
