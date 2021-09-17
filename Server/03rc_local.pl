#!/usr/bin/perl

use strict;
use warnings;
use Env::Modify qw(:sh source);
######### The following ($rclocal) is the default content
`echo "#!/bin/bash" > /etc/rc.local`; 					
`echo "touch /var/lock/subsys/local" >> /etc/rc.local`; #ori
`echo "sysctl net.ipv4.ip_forward=1" >> /etc/rc.local`; #share net for every node
`echo "systemctl restart slurmctld" >> /etc/rc.local`; #slurmctl


`chmod +x /etc/rc.d/rc.local`; # let rc.local can start when reboot

system ("sysctl net.ipv4.ip_forward=1");
source ("/etc/rc.local"); 
print "\n\n***###01rc_local.pl: set rc.local done******\n\n";
