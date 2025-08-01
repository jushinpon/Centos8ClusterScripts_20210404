#!/usr/bin/perl
use strict;
use warnings;

# [✓ Retained] Enable NetworkManager (no need to install network-scripts)
system("systemctl enable NetworkManager");

# [✓ Retained] Disable firewall
system("systemctl stop firewalld");
system("systemctl disable firewalld");

# [✓ Retained] Read server settings
open my $ss, "< ./Server_setting.dat" or die "No Server_setting.dat to open.\n $!";
my @temp_array = <$ss>;
close $ss;

my @temp_array1 = grep { $_ !~ m{^\s*$|^#} } @temp_array;
my %ServerSetting;
for (@temp_array1){
    $_ =~ s/^\s+|\s+$//g;
    my @temp = split(/=/, $_);
    $temp[0] =~ s/^\s+|\s+$//g;
    $temp[1] =~ s/^\s+|\s+$//g;
    chomp($temp[0]);
    chomp($temp[1]);
    $ServerSetting{$temp[0]} = $temp[1];
}

# [✓ Retained] Get active NIC
my $temp = `ip a | grep "state UP"`;
my @temp = split "\n", $temp;
my @temp1 = grep { $_ !~ m{^\s*$} } @temp;
my $upStateNo = @temp1;
if ($upStateNo > 1){ die "The Number \($upStateNo\) of up state NIC is more than one!!\n"; }
$temp1[0] =~ m{:\s+(.+)\s*:};
chomp $1;
print "NIC: $1\n";
if ($1 eq ""){ die "No NIC exists\n"; }

my $Nic_inner = $1;

# [✓ Retained] Extract IP info and calculate node ID
`ip a` =~ m{192.168.0.(\d{1,3})/24};
my $fourthdigital = $1;
my $nodeID = $fourthdigital - 1;
my $ipne = `ip add show $Nic_inner`;
$ipne =~ /(\w+:\w+:\w+:\w+:\w+:\w+)/;
my $mac = $1;
$nodeID =~ s/^\s+|\s+$//;
chomp($nodeID);
my $formatted_nodeID = sprintf("%02d", $nodeID);
my $hostname = "node$formatted_nodeID";

# [✓ Retained] Hostname + domain settings
`domainname $ServerSetting{domainname}`;
`echo $hostname > /etc/hostname`;
`hostname $hostname`;
`hostnamectl set-hostname $hostname`;

# [✗ Replaced] Remove legacy ifcfg-* file editing; use nmcli instead

# Delete existing connection if exists
my $conn_name = `nmcli -t -f NAME,DEVICE connection show --active | grep $Nic_inner | cut -d: -f1`;
chomp($conn_name);
if ($conn_name) {
    system("nmcli connection delete \"$conn_name\"");
}

# Add a new static IP connection using nmcli
my $ipaddr = "192.168.0.$fourthdigital";
system("nmcli connection add type ethernet ifname $Nic_inner con-name $Nic_inner autoconnect yes ip4 $ipaddr/24 gw4 192.168.0.101");

# Apply DNS and MAC settings
system("nmcli connection modify $Nic_inner ipv4.dns \"8.8.8.8 140.117.11.1\"");
system("nmcli connection modify $Nic_inner ethernet.cloned-mac-address $mac");
system("nmcli connection modify $Nic_inner ipv4.method manual");

# Apply MTU if defined
if (defined $ServerSetting{MTU}) {
    system("nmcli connection modify $Nic_inner 802-3-ethernet.mtu $ServerSetting{MTU}");
}

# Bring up the connection
system("nmcli connection up $Nic_inner");

# [✓ Retained] Chrony time sync and timezone setup
system("dnf install -y chrony");
system("systemctl start chronyd");
system("systemctl enable chronyd");
system("timedatectl set-timezone Asia/Taipei");
