## basic setting
#!/usr/bin/perl
# GATEWAY is require to set for CENTOS 8
use strict;
use warnings;
use Cwd; #Find Current Path

my $GetIP_file= "yes";# if yes (from 2 to 30 currently), "ping" will get you Nodes_IP.txt. If not, you 
# need to get your own when installation for new nodes in the future

system("systemctl restart NetworkManager");
system("systemctl enable NetworkManager");   


#Reading required information for Server 
open my $ss,"< ./Server_setting.dat" or die "No Server_setting.dat to open.\n $!";
my @temp_array = <$ss>;
close $ss; 

my @temp_array1=grep (($_!~m{^\s*$|^#}),@temp_array); # remove blank lines
my %ServerSetting; # keep all information for Server setting
for (@temp_array1){
	$_  =~ s/^\s+|\s+$//;
	my @temp = split (/=/,$_) ;
	$temp[0]  =~ s/^\s+|\s+$//;
	chomp ($temp[0]);
	$temp[1]  =~ s/^\s+|\s+$//;
	chomp ($temp[1]);
	$ServerSetting{$temp[0]} = $temp[1] ;
}

# get MAC of each internet card
my %mac;
for ($ServerSetting{if_internet}){
      my $ipne = `ip add show $_`;      
      $ipne =~ /(\w+:\w+:\w+:\w+:\w+:\w+)/;# the first matched item is mac!
      chomp $1;
      $mac{$_}="$1";  
}

#internet setting
if($ServerSetting{machinetype} ne "virtualbox"){
`echo "BOOTPROTO=static" > /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_internet}`;#open a new file
`echo "DNS1=$ServerSetting{dns_nameservers1}" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_internet}`;
`echo "DNS2=$ServerSetting{dns_nameservers2}" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_internet}`;
`echo "GATEWAY=$ServerSetting{gateway}" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_internet}`;
`echo "DEVICE=$ServerSetting{if_internet}" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_internet}`;#append the data into the file
`echo "NAME=$ServerSetting{if_internet}" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_internet}`;
`echo "ONBOOT=yes" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_internet}`;
`echo "IPADDR=$ServerSetting{IP_address}" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_internet}`;
`echo "NETMASK=$ServerSetting{netmask}" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_internet}`;
#`echo "UUID=$nmcli{$ServerSetting{if_internet}}" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_internet}`;
`echo "HWADDR=$mac{$ServerSetting{if_internet}}" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_internet}`; 
`echo "DEFROUTE=yes" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_internet}`;
`echo "TYPE=Ethernet" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_internet}`;

#restart networking
	for ($ServerSetting{if_internet}){
		#system("ifup $_");## configure the NIC
		system("ifdown $_ ");## stop this NIC and force it to use new seeting by the following command 
		system("ip addr flush dev $_");## remove all previous setting (because we want to assign new informatio)  
		system("ifup $_"); ## use new setting
	}
}
# Centos 8 doesn't use network.service anymore

if ($GetIP_file eq "yes"){
      unlink("./Nodes_IP.dat");
      open my $ss,">./Nodes_IP.dat";
     
      for (2..50){
      	my $temp = "192.168.0.$_";
		chomp $temp;  
      	system("ping -c 1 $temp");
      		if($? eq 0){
      		   print  "** IP exists: $? $temp\n";# for the following Perl scripts
      		   print $ss "$temp\n";# for the following Perl scripts
      		}
      		else{
      		   print  "** IP not exist: $? $temp\n";# for the following Perl scripts
      		   print $ss "# ping not works for : $temp\n";	
      		}
      }
     close($ss);
}
print "\n Check Nodes_IP.dat\n!!";
