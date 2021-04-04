=start_form
use vi to modify the ifcfg- file in /etc/sysconfig/network-scripts/$NetCard
1.
BOOTPROTO=static <---
ONBOOT=yes  <---
IPADDR=192.168.0.1  <--- set IP here and then we can use scp from server to do all settings
2.
then ifup XXXX
=cut
#!/usr/bin/perl
use strict;
use warnings;

#system("systemctl restart NetworkManager");
system("systemctl enable NetworkManager");

#Reading required information for node 
open my $ss,"< ./Server_setting.dat" or die "No Server_setting.dat to open.\n $!";
my @temp_array = <$ss>;
close $ss; 

my @temp_array1=grep (($_!~m{^\s*$|^#}),@temp_array); # remove blank lines
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

#get internet card name
my $temp = `ip a|grep "state UP"`;
my @temp = split "\n", $temp;
my @temp1 = grep (($_!~m{^\s*$}),@temp); # remove blank lines
my $upStateNo = @temp1;
if ($upStateNo > 1){die "The Number \($upStateNo\) of up state NIC is more than one!!\n";}
$temp1[0] =~ m{:\s+(.+)\s*:};
chomp $1;
print "NIC: $1\n";
if ($1 eq ""){die "No NIC exits\n";}

my $Nic_inner = $1;
`ip a`=~ m{192.168.0.(\d{1,3})\/24};
my $fourthdigital = $1;
my $nodeID = $fourthdigital - 1;# node ID according to th fourth number of current IP
# get MAC of each internet card
my %mac;
my $ipne = `ip add show $Nic_inner`;      
$ipne =~ /(\w+:\w+:\w+:\w+:\w+:\w+)/;# the first matched item is mac!
$mac{$Nic_inner}="$1";      
$nodeID =~ s/^\s+|\s+$//;
chomp($nodeID);
my $formatted_nodeID = sprintf("%02d",$nodeID);
my $hostname="node"."$formatted_nodeID";

`domainname $ServerSetting{domainname}`;# give domainname of your cluster
`echo $hostname > /etc/hostname`;
`hostname $hostname`;
`hostnamectl set-hostname $hostname`;

#inner net setting
`echo "BOOTPROTO=static" > /etc/sysconfig/network-scripts/ifcfg-$Nic_inner`;
`echo "DEVICE=$Nic_inner" >> /etc/sysconfig/network-scripts/ifcfg-$Nic_inner`;
`echo "NAME=$Nic_inner" >> /etc/sysconfig/network-scripts/ifcfg-$Nic_inner`;
`echo "ONBOOT=yes" >> /etc/sysconfig/network-scripts/ifcfg-$Nic_inner`;
`echo "IPADDR=192.168.0.$fourthdigital" >> /etc/sysconfig/network-scripts/ifcfg-$Nic_inner`;
`echo "NETMASK=255.255.255.0" >> /etc/sysconfig/network-scripts/ifcfg-$Nic_inner`;
`echo "GATEWAY=192.168.0.101" >> /etc/sysconfig/network-scripts/ifcfg-$Nic_inner`;
`echo "DNS1=8.8.8.8" >> /etc/sysconfig/network-scripts/ifcfg-$Nic_inner`;
`echo "DNS2=140.117.11.1" >> /etc/sysconfig/network-scripts/ifcfg-$Nic_inner`;
`echo "BROADCAST=192.168.0.255" >> /etc/sysconfig/network-scripts/ifcfg-$Nic_inner`;
#`echo "UUID=$nmcli{$Nic_inner}" >> /etc/sysconfig/network-scripts/ifcfg-$Nic_inner`;
`echo "HWADDR=$mac{$Nic_inner}" >> /etc/sysconfig/network-scripts/ifcfg-$Nic_inner`; 
`echo "TYPE=Ethernet" >> /etc/sysconfig/network-scripts/ifcfg-$Nic_inner`;
`echo "MTU=$ServerSetting{MTU}" >> /etc/sysconfig/network-scripts/ifcfg-$Nic_inner`;

system("ifdown $Nic_inner");## stop this NIC and force it to use new seeting by the following command 
system("ip addr flush dev $Nic_inner");## remove all previous setting (because we want to assign new informatio)  
system("ifup $Nic_inner"); ## use new setting

#system('systemctl restart NetworkManager');
#system("killall -9 yum");
system("dnf install -y chrony");#time sync
system("systemctl start chronyd");#time sync
system("systemctl enable chronyd");#time sync

system("timedatectl set-timezone Asia/Taipei");## setting timezone


