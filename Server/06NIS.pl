## You Need install ypbind yp-tools ypserv rpcbind first
#!/usr/bin/perl

use strict;
use warnings;
## yum -y install ypbind yp-tools ypserv rpcbind 

`ypdomainname melcluster`;
`nisdomainname melcluster`;
`echo "NISDOMAIN=melcluster" > /etc/sysconfig/network`;
`echo 'YPSERV_ARGS="-p 955"' >> /etc/sysconfig/network`;
`echo 'YPXFRD_ARGS="-p 956"' >> /etc/sysconfig/network`;

`echo 'YPPASSWDD_ARGS="-p 957"' > /etc/sysconfig/yppasswdd`;

`echo "255.0.0.0    127.0.0.0" > /var/yp/securenets`;
`echo "255.255.255.0    192.168.0.0" >> /var/yp/securenets`;
`echo "domain melcluster server master" > /etc/yp.conf`;

system("perl -p -i.bak -e 's/.*dns:.+\n//g;' /etc/ypserv.conf");# remove old setting lines
`echo 'dns: no' >> /etc/ypserv.conf`;

system("systemctl start  ypbind ypserv ypxfrd yppasswdd");
system("systemctl enable  ypbind ypserv ypxfrd yppasswdd nis-domainname");
`echo -e "\004" | /usr/lib64/yp/ypinit -m`;
system("systemctl restart  ypbind ypserv ypxfrd yppasswdd");

system ("firewall-cmd --zone=internal --add-service=rpc-bind --permanent");
system("firewall-cmd --zone=internal --add-port={955-957/tcp,955-957/udp} --permanent");
system(" firewall-cmd --reload");

print "\n\n***###04NIS.pl: set NIS done******\n\n";
#yptest, ypwhich for check

