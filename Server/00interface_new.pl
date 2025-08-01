#!/usr/bin/perl
use strict;
use warnings;
use Cwd;

# [Unchanged] Option to regenerate Nodes_IP.dat via ping
my $GetIP_file = "yes";

# [✓ Retained] Restart and enable NetworkManager (still valid in Rocky 8)
system("systemctl restart NetworkManager");
system("systemctl enable NetworkManager");

# [✗ Removed] No need to install 'network-scripts' anymore (deprecated)
# system("dnf -y install network-scripts");  ## <-- Removed: no longer necessary

# [✓ Retained] Read server settings from file
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

# [✓ Retained] Get MAC address of specified NIC
my %mac;
for ($ServerSetting{if_internet}) {
    my $ipne = `ip addr show $_`;
    $ipne =~ /(\w+:\w+:\w+:\w+:\w+:\w+)/;
    chomp $1;
    $mac{$_} = $1;
}

# [✗ Rewritten] Use nmcli instead of writing /etc/sysconfig/network-scripts/ifcfg-* files
if ($ServerSetting{machinetype} ne "virtualbox") {
    my $iface = $ServerSetting{if_internet};

    # [✓ Added] Delete existing connection if it exists to avoid conflicts
    my $conn_name = `nmcli -t -f NAME,DEVICE connection show --active | grep $iface | cut -d: -f1`;
    chomp($conn_name);
    if ($conn_name) {
        system("nmcli connection delete \"$conn_name\"");
    }

    # [✓ Added] Create new static connection via nmcli
    system("nmcli connection add type ethernet ifname $iface con-name $iface autoconnect yes ip4 $ServerSetting{IP_address}/24 gw4 $ServerSetting{gateway}");

    # [✓ Replaced] Set DNS using nmcli instead of appending DNS1/DNS2 in config files
    system("nmcli connection modify $iface ipv4.dns \"$ServerSetting{dns_nameservers1} $ServerSetting{dns_nameservers2}\"");

    # [✓ Replaced] Set MAC address with NetworkManager format
    system("nmcli connection modify $iface ethernet.cloned-mac-address $mac{$iface}");

    # [✓ Replaced] Bring up the new connection using nmcli
    system("nmcli connection up $iface");
}

# [✓ Retained] Generate Nodes_IP.dat by pinging a range of IPs
if ($GetIP_file eq "yes") {
    unlink("./Nodes_IP.dat");
    open my $ss, "> ./Nodes_IP.dat" or die "Cannot create Nodes_IP.dat: $!";
    
    for my $i (2..50) {
        my $temp = "192.168.0.$i";
        system("ping -c 1 $temp > /dev/null 2>&1");
        if ($? == 0) {
            print "** IP exists: $temp\n";
            print $ss "$temp\n";
        } else {
            print "** IP not exist: $temp\n";
            print $ss "# ping not works for: $temp\n";
        }
    }
    close($ss);
}

# [✓ Retained] Final message
print "\nCheck Nodes_IP.dat\n!!\n";
