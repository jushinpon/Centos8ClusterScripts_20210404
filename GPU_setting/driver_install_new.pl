use warnings;
use strict;
use Parallel::ForkManager;

# List of nodes where GPU drivers need to be fixed
my @gpuNodes = qw(
node24
node28
node40
node18
node20
);

# Number of parallel processes
my $forkNo = 10;
my $pm = Parallel::ForkManager->new($forkNo);

# Define the full sequence of commands to clean, reinstall, and verify NVIDIA drivers for Rocky Linux 8
my @commands = (
    "dnf autoremove '*nvidia*' -y",
    "dnf clean all",
    "dnf remove '*cublas*' 'cuda*' -y",
    "dnf remove '*nvidia*' -y",
    "dnf install elrepo-release -y",
    "dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-rhel8.repo",
    "dnf module reset nvidia-driver -y",
    "dnf module enable nvidia-driver:latest-dkms -y",
    "dnf install -y nvidia-driver kernel-devel-\$(uname -r) kernel-headers-\$(uname -r)",
    "dnf install -y epel-release",
    "dnf install -y https://download1.rpmfusion.org/free/el/rpmfusion-free-release-8.noarch.rpm",
    "dnf install -y cuda",
    "dnf install -y nvidia-gds",
    "dnf clean all",
    "modprobe -r nvidia",
    "modprobe -r nvidia_drm",
    "modprobe -r nvidia_modeset",
    "modprobe -r nvidia_uvm",
    "modprobe nvidia",
    "modprobe nvidia_drm",
    "modprobe nvidia_modeset",
    "modprobe nvidia_uvm",
    "systemctl restart nvidia-persistenced",
    "update-pciids",
    "lspci | grep -i nvidia",
    "nvidia-smi",
    "cat /proc/driver/nvidia/version",
    "dmesg | grep NVRM",
    #"reboot"
);

my $cmd_sequence = join(";", @commands);

# Execute on each node
for my $node (@gpuNodes) {
    $pm->start and next;
    
    print "***** Processing node: $node *****\n";
    my $cmd = "/usr/bin/ssh $node ";
    
    # Execute the full sequence of commands on the node
    system("$cmd '$cmd_sequence'");
    
    print "*** GPU Driver Status for node $node: ***\n";
    system("$cmd 'nvidia-smi'");
    system("$cmd 'cat /proc/driver/nvidia/version'");
    system("$cmd 'dmesg | grep NVRM'");
    
    $pm->finish;
}

$pm->wait_all_children;

print "GPU driver installation and verification completed on all nodes.\n";
