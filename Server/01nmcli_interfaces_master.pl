#!/usr/bin/perl
use strict;
use warnings;
use Cwd;

open my $pack, "> ./FailedPackageInstall.dat";

# Load settings
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

# Set domain and hostname
system("domainname $ServerSetting{domainname}");
system("hostname master");
system("echo master > /etc/hostname");
system("hostnamectl set-hostname master");
system("nisdomainname $ServerSetting{domainname}");

# Get MAC addresses
my %mac;
for ($ServerSetting{if_internet}, $ServerSetting{if_private}) {
    my $ipne = `ip add show $_`;
    $ipne =~ /(\w+:\w+:\w+:\w+:\w+:\w+)/;
    chomp $1;
    $mac{$_} = $1;
}

# Configure interfaces using nmcli
foreach my $iface ($ServerSetting{if_internet}, $ServerSetting{if_private}) {
    # Remove any existing connection
    my $conn = `nmcli -t -f NAME,DEVICE connection show --active | grep $iface | cut -d: -f1`;
    chomp($conn);
    system("nmcli connection delete \"$conn\"") if $conn;

    if ($iface eq $ServerSetting{if_internet}) {
        # External interface
        system("nmcli connection add type ethernet ifname $iface con-name $iface autoconnect yes ip4 $ServerSetting{IP_address}/24 gw4 $ServerSetting{gateway}");
        system("nmcli connection modify $iface ipv4.dns \"$ServerSetting{dns_nameservers1} $ServerSetting{dns_nameservers2}\"");
    } else {
        # Internal interface
        system("nmcli connection add type ethernet ifname $iface con-name $iface autoconnect yes ip4 192.168.0.101/24");
        system("nmcli connection modify $iface ipv4.dns \"8.8.8.8 140.117.11.1\"");
    }

    # Common settings
    system("nmcli connection modify $iface ipv4.method manual");
    system("nmcli connection modify $iface ethernet.cloned-mac-address $mac{$iface}");
    system("nmcli connection modify $iface 802-3-ethernet.mtu $ServerSetting{MTU}") if $ServerSetting{MTU};
    system("nmcli connection up $iface");
}

# Enable powertools
system("yum install -y 'dnf-command(config-manager)'");
system("dnf install dnf-plugins-core -y");
system("dnf config-manager --set-enable powertools");

# Clean up yum
system("rm -rf /var/run/yum.pid");

# Install packages
my @package = (
    "cmake","vim", "wget", "net-tools", "epel-release", "htop", "make", "numactl-devel", "fail2ban",
    "openssh*", "nfs-utils", "ypserv", "yp-tools", "geany", "psmisc",
    "firewalld", "ypbind", "rpcbind", "perl-Expect", "gcc-gfortran", "xorg-x11-server-Xorg", "xorg-x11-xauth",
    "perl-MCE-Shared", "perl-Parallel-ForkManager", "tmux", "perl-CPAN", "yum-utils", "dos2unix"
);
system("dnf -y install perl* --nobest --skip-broken");
foreach (@package) {
    system("dnf -y install $_");
    print $pack "$_ installation failed!!!!!\n" if $?;
}

# Install Intel MKL
system("yum-config-manager --add-repo https://yum.repos.intel.com/mkl/setup/intel-mkl.repo") == 0 or die "add intel repo failed!\n";
system("rpm --import https://yum.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB") == 0 or die "import intel repo key failed!\n";
system("yum install -y intel-mkl");

# Perl CPAN modules
system("echo 'yes' | cpan App::cpanminus");
system("cpanm Env::Modify --force");
system("cpanm Parallel::ForkManager --force");
system("cpanm Expect --force");
system("cpanm Statistics::Descriptive --force");
system("cpanm MCE::Shared --force");
print $pack "Env::Modify installation failed!!!!!\n" if $?;

# Upgrade all packages
system("dnf -y upgrade");

# SSH server config tweaks
`sed -i "/X11Forwarding/d" /etc/ssh/sshd_config`;
`sed -i '\$ a X11Forwarding yes' /etc/ssh/sshd_config`;
`sed -i "/GSSAPIAuthentication/d" /etc/ssh/sshd_config`;
`sed -i '\$ a GSSAPIAuthentication no' /etc/ssh/sshd_config`;
`sed -i "/UseDNS/d" /etc/ssh/sshd_config`;
`sed -i '\$ a UseDNS no' /etc/ssh/sshd_config`;

system("systemctl restart sshd");

# Chrony time sync
system("dnf install -y chrony");
system("systemctl start chronyd");
system("systemctl enable chronyd");
system("timedatectl set-timezone Asia/Taipei");

# Disable dnf-automatic
system("systemctl stop dnf-automatic");
system("systemctl disable dnf-automatic");
system("dnf remove dnf-automatic -y");
system("systemctl stop dnf-makecache.timer");
system("systemctl disable dnf-makecache.timer");

close($pack);

print "\n\n***###00interfaces_master.pl: set internet card done******\n\n";
print "Please check FailedPackageInstall.dat!!!\n";
