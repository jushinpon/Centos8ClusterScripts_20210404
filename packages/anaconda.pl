=b
This script installs anaconda automatically
check the following first:

1. https://docs.anaconda.com/free/anaconda/install/linux/
2. https://repo.anaconda.com/archive/     <---- check the latest version

=cut

use warnings;
use strict;
use Cwd; #Find Current Path
use Expect;  

my $wgetORgit = "yes";#yes or no
my $current_path = getcwd();# get the current path dir
#for qt
#system("yum install libXcomposite libXcursor libXi libXtst libXrandr alsa-lib mesa-libEGL libXdamage mesa-libGL libXScrnSaver -y");
# Replace <INSTALLER_VERSION> with the version of the installer file you want to download
# For example, https://repo.anaconda.com/archive/Anaconda3-2023.09-0-Linux-x86_64.sh
# All installers can be found at repo.anaconda.com/archive/
my $version = '2024.10-1';
#system("curl -O https://repo.anaconda.com/archive/Anaconda3-$version-Linux-x86_64.sh");
system("bash ./Anaconda3-$version-Linux-x86_64.sh -b -p /opt/anaconda3");

