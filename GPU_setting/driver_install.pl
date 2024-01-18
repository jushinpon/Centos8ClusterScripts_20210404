=b
./NVIDIA-Linux-x86_64-535.113.01.run --uninstall
yum autoremove nvidia* -y
yum autoremove "*cublas*" "cuda*" -y
yum autoremove "*nvidia*" -y

yum remove "*cublas*" "cuda*"
yum remove "*nvidia*"

dnf install elrepo-release
dnf install nvidia-detect
nvidia-detect

sudo dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-rhel8.repo
sudo dnf -y module install nvidia-driver:latest-dkms

dnf config-manager --disable elrepo   # just disable, hide, repo -- dnf will not use that repo
dnf remove elrepo-release             # totally remove the definition -- dnf does not know about ELrepo
dnf module list nvidia-driver
dnf module reset nvidia-driver
dnf module enable nvidia-driver:460
dnf module install nvidia-driver:460

dnf install elrepo-release

update-pciids
lspci | grep -i nvidia
dnf install kernel-devel-$(uname -r) kernel-headers-$(uname -r)
dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
dnf install subscription-manager

subscription-manager repos --enable=rhel-8-for-x86_64-appstream-rpms
subscription-manager repos --enable=rhel-8-for-x86_64-baseos-rpms
subscription-manager repos --enable=codeready-builder-for-rhel-8-x86_64-rpms
sudo dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-rhel8.repo
rpm --erase gpg-pubkey-7fa2af80*
dnf clean expire-cache
dnf module install nvidia-driver:latest-dkms
dnf install cuda
dnf install nvidia-gds

nvidia-gds

sudo dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-rhel8.repo
sudo dnf clean all
sudo dnf -y module install nvidia-driver:latest-dkms
sudo dnf -y install cuda

dnf install kernel-devel-$(uname -r) kernel-headers-$(uname -r)
dnf install epel-release

dnf install https://download1.rpmfusion.org/free/el/rpmfusion-free-release-8.noarch.rpm
dnf install nvidia-driver

 nvidia-smi 
Failed to initialize NVML: Driver/library version mismatch
cat /proc/driver/nvidia/version 
NVRM version: NVIDIA UNIX x86_64 Kernel Module  535.113.01  Tue Sep 12 19:41:24 UTC 2023
dmesg|grep NVRM -->API mismatch
=cut

use warnings;
use strict;
use Parallel::ForkManager;

my @badgpuNodes = qw(
node09
node12
node18
);

my $forkNo = 1;
my $pm = Parallel::ForkManager->new("$forkNo");
my @dnf = ("dnf install elrepo-release -y",
            #"dnf install nvidia-detect -y",
"dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-rhel8.repo",
          # "dnf module reset nvidia-driver -y",
#"dnf module enable nvidia-driver:525",
#"dnf module install -y nvidia-driver:525",
            "sudo dnf -y module install nvidia-driver:latest-dkms"
);
my $dnf = join(";",@dnf);
chomp $dnf;
#my %nodes = (
#    #161 => [0],#8..18,20..22,39..41],#[1,3,39..42],#1,3,39..
#    #161 => [8..18],#8..18,20..22,39..41],#[1,3,39..42],#1,3,39..
#    #161 => [10],#[1,3,39..42],#1,3,39.., bad node 18
#    161 => [1,2,3,8..10,11..18,20..21,39..42],#[1,3,39..42],#1,3,39..    
#    #161 => [1..3],#[1,3,39..42],#1,3,39..    
#    182 => [23]
#    #182 => [7,20,21,22,23,24]
#    );
##get current for the corresponding setting    
#my $ip = `/usr/sbin/ip a`;    
#$ip =~ /1\d0\.1\d\d\.\d+\.(\d+)/;
#my $cluster = $1;
#$cluster =~ s/^\s+|\s+$//;
##print "\$cluster: $cluster\n";
#my @allnodes = @{$nodes{$cluster}};#get node information
#my @nodes;
#
#test whether the connection is ok
#`touch ~/scptest.dat`;
#for (@allnodes){
#    my $nodeindex=sprintf("%02d",$_);
#    my $nodename= "node"."$nodeindex";
#    my $cmd = "/usr/bin/ssh $nodename ";
#    print "****Check $nodename status\n ";
#    #`echo "***$nodename" >> $output`;
##use scp for ssh test
#	system("scp -o ConnectTimeout=5 ~/scptest.dat root\@$nodename:/root");    
#    if($?){
#		next;#not available
#		}
#	else{
#		print "scp at $nodename ok for ssh test\n";
#        push @nodes, $_;
#		}	
#}
#chomp @nodes;

for (@badgpuNodes){
#$pm->start and next;
    
    print "*****$_*****\n";
    my $cmd = "/usr/bin/ssh $_ ";
    #for my $dnf (@dnf){
        system("$cmd '$dnf'");
    #}

#$pm->finish;
}
#$pm->wait_all_children;