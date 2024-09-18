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

nvidia-smi: 
Failed to initialize NVML: Driver/library version mismatch
cat /proc/driver/nvidia/version 
NVRM version: NVIDIA UNIX x86_64 Kernel Module  535.113.01  Tue Sep 12 19:41:24 UTC 2023
dmesg|grep NVRM -->API mismatch
=cut

use warnings;
use strict;
use Parallel::ForkManager;

my @badgpuNodes = qw(
node07
);

my $forkNo = 1;
my $pm = Parallel::ForkManager->new("$forkNo");
my @dnf = ("dnf remove nvidia* -y","dnf install elrepo-release -y",
            #"dnf install nvidia-detect -y",
"dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-rhel8.repo",
           "dnf module reset nvidia-driver -y",
"dnf module enable nvidia-driver:525",
"dnf module install -y nvidia-driver:525",
            #"sudo dnf -y module install nvidia-driver:latest-dkms",
            #"dnf install kmod-nvidia -y",
            "dnf update -y",
            #"reboot"
);
my $dnf = join(";",@dnf);
chomp $dnf;

for (@badgpuNodes){
#$pm->start and next;
    
    print "*****$_*****\n";
    my $cmd = "/usr/bin/ssh $_ ";
    #for my $dnf (@dnf){
        system("$cmd '$dnf'");
    #check the version consistency:    
        system("$cmd '$dnf'");
        print "***Check GPU driver status for node $_:\n";
        system("$cmd 'cat /proc/driver/nvidia/version'");
        system("$cmd 'dmesg|grep NVRM'");
         
#NVRM version: NVIDIA UNIX x86_64 Kernel Module  535.113.01  Tue Sep 12 19:41:24 UTC 2023
#dmesg|grep NVRM -->API mismatch
    #}

#$pm->finish;
}
#$pm->wait_all_children;