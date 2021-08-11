#https://dywang.csie.cyut.edu.tw/dywang/rhce7/node20.html
=be
#firewall-cmd --list-all-zones
#firewall-cmd --get-default-zone 
#firewall-cmd --set-default-zone public --permanent
#firewall-cmd --permanent --zone=public --list-all
#firewall-cmd --runtime-to-permanent
#firewall-cmd --reload
firewall-cmd --list-rich-rules

=cut



use strict;
use warnings;
system("systemctl start firewalld");

system("systemctl mask iptables.service");
system("systemctl mask ip6tables.service");
system("systemctl mask ebtables.service");
system ("sysctl net.ipv4.ip_forward=1");
system ("sysctl -p");
 
open my $ss1,"< ./Server_setting.dat" or die "No Server_setting.dat to open.\n $!";
my @temp_array = <$ss1>;
my @temp_array1=grep (($_!~m{^\s*$|^#}),@temp_array);
my % ServerSetting; # keep all information for Server setting
for (@temp_array1){
	$_  =~ s/^\s+|\s+$//;
	my @temp = split (/=/,$_) ;
	$temp[0]  =~ s/^\s+|\s+$//;
	chomp ($temp[0]);
	$temp[1]  =~ s/^\s+|\s+$//;
	chomp ($temp[1]);
	$ServerSetting{$temp[0]} = $temp[1] ;
}
my $cmd = 'firewall-cmd';
#system ("sudo systemctl restart NetworkManager.service");
#system ("service firewalld restart");
#system ("systemctl enable firewalld");

#if_internet = enp3s0  
#if_private = enp0s29u1u1
#firewall-cmd --get-zone-of-interface=enp3s0
system ("$cmd --set-default-zone=external"); 
system ("$cmd --permanent --zone=external --change-interface=$ServerSetting{if_internet}"); #set default zone=block block is the second most stringent setting.
system ("$cmd --get-zone-of-interface=$ServerSetting{if_internet}"); #set ifcard zone=block.
#`echo "ZONE=external" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_internet}`;#set ifcard zone=block.
#system ("systemctl restart NetworkManager");

#`firewall-cmd --add-rich-rule='rule family="ipv4" source address="192.168.0.0/24" accept'`;
   
#system ("firewall\-cmd \-\-zone\=external \\
#  \-\-add\-rich\-rule\=\'rule family\=\"ipv4\" source address\=\"140\.117\.0\.0\/24\" accept\' \\
#  \-\-permanent");
#system ("$cmd --reload");
 #system ("$cmd --list-all"); #Check that the setup is all complete or not. 
#print "firewallD setting all done\n";
#sleep (5);
############################# FIREWALLD DONE!!
#`echo "net.ipv4.ip_forward = 1" > /etc/sysctl.conf`; # IP forwarding enable
#system ("sysctl -p"); # Entry into force of the command
system ("$cmd --permanent --zone=internal --change-interface=$ServerSetting{if_private}"); # private net zone setting 
#system ("$cmd --permanent --zone=external --add-masquerade ");# ip camouflage
system ("$cmd --permanent --zone=external --passthrough ipv4 -t nat POSTROUTING -o $ServerSetting{if_internet} -j MASQUERADE -s 192.168.0.0/24"); #share internet in 192.168.0.0
system ("$cmd --permanent --zone=external --add-service=ftp"); #allow the ftp service to work
#system ("firewall-cmd --permanent --zone=internal --add-rich-rule=\'rule family=\"ipv4\" source address=\"192.168.0.0/24\" accept\'");
#sleep(10);

system ("$cmd --permanent --zone=external --add-forward-port=port=1122:proto=tcp:toport=22");#:toaddr=192.168.0.0/24");
#NFS service
system ("$cmd --permanent --zone=internal --add-service=nfs");
system ("$cmd --permanent --zone=internal --add-service=rpc-bind");
system ("$cmd --permanent --zone=internal --add-service=mountd");
system ("$cmd --permanent --zone=internal --add-source=192.168.0.0/24");#:toaddr=192.168.0.0/24");
system("firewall-cmd --zone=external --add-port=139/tcp --permanent"); # for samba
`firewall-cmd --permanent --direct --add-rule ipv4 filter INPUT 0 -s 192.168.0.0/24  -j ACCEPT`;
system ("$cmd --reload"); #reload
#for (2..30){system ("$cmd --zone=external --add-forward-port=port=1122:proto=tcp:toport=22:toaddr=192.168.0.$_ --permanent");}
#system ("$cmd --reload"); #reload
#system ("$cmd --permanent --zone=external --change-interface=$ServerSetting{if_internet}");#change zone to block
#system ("$cmd --reload"); #reload
#system ("service firewalld restart");
print "\nfirewalld setting DONE\n";
############################  Network Address Translation DONEEEEE :) 
 
