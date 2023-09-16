yum autoremove nvidia*
yum remove "*cublas*" "cuda*"
yum remove "*nvidia*"

dnf install elrepo-release
dnf install nvidia-detect
nvidia-detect

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
