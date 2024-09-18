#https://www.dhondt.de/ccx_2.21.README.INSTALL
# Perl script to install SPOOLES 2.2, ARPACK, and CalculiX 2.21 from scratch on Rocky Linux 8
#sub path_setting{
#	my $attached_path = shift;	
#	my $path = $ENV{'PATH'};
#	$ENV{'PATH'} = "$attached_path:$path";
#}
#	
#sub ld_setting {
#    my $attached_ld = shift;
#	my $ld_library_path = $ENV{'LD_LIBRARY_PATH'};	
#	$ENV{'LD_LIBRARY_PATH'} = "$attached_ld:$ld_library_path";		
#}
#my $mattached_path = "/opt/mpich-4.0.3/bin";#attached path in main script
#path_setting($mattached_path);
##/opt/intel/compilers_and_libraries_2018.0.128/linux/mkl/lib/intel64_lin
#my $mattached_ld = "/opt/mpich-4.0.3/lib";#attached ld path in main script
#ld_setting($mattached_ld);
#
## Setting up environment variables for installation
#sub setup_environment {
#    my ($path, $ld_library_path) = @_;
#    $ENV{'PATH'} = "$path:$ENV{'PATH'}";
#    $ENV{'LD_LIBRARY_PATH'} = "$ld_library_path:$ENV{'LD_LIBRARY_PATH'}" if $ld_library_path;
#}
#
#my $gcc_path = "/usr/bin"; # Adjust as necessary
#my $lib_path = "/usr/lib64"; # Adjust as necessary
#setup_environment($gcc_path, $lib_path);
#!/bin/sh

use warnings;
use strict;
use Cwd; # Current Path

my $wgetORgit = "yes";## if you want to download the source, use yes. set no, if you have downloaded the source.
my $script_CurrentPath = getcwd(); #get perl code path

my $packageDir = "/home/packages";
unless (-e $packageDir) {
    system("mkdir -p $packageDir");
}

# Download and install SPOOLES 2.2
#my $spooles_url = "https://www.netlib.org/linalg/spooles/spooles.2.2.tgz"; 
#my $spooles_dir = "/usr/local/SPOOLES.2.2";
#my $spooles_file = "spooles.2.2.tgz";
#if($wgetORgit eq "yes"){
#    `rm -rf $spooles_dir`;
#    `mkdir -p $spooles_dir`;
#    chdir $spooles_dir;
#    system("wget $spooles_url");
#    system("tar -xzf $spooles_file");
#    system("sed -i 's|CC = /usr/lang-4.0/bin/cc|#CC = /usr/lang-4.0/bin/cc|' Make.inc");
#    system("sed -i 's|# CC = gcc|CC = gcc|' Make.inc");
#    system("sed -i 's|CFLAGS = .*|CFLAGS = -O -D_SPOOLES_MT -pthread|' Make.inc");
#    system("sed -i 's|#cd MT/src             ; make -f makeGlobalLib|    cd MT/src             ; make -f makeGlobalLib|' Makefile");    
#}
#
#chdir $spooles_dir;
#system("make lib"); # Build the SPOOLES library
#chdir("$script_CurrentPath");
#### end of spooles installation


## Download and install ARPACK
##my $arpack_url = "https://github.com/opencollab/arpack-ng/archive/refs/tags/3.8.0.tar.gz"; 

my $arpack_url = "https://web.archive.org/web/20220526222500fw_/https://www.caam.rice.edu/software/ARPACK/SRC/arpack96.tar.Z"; 
my $arpackpatch_url = "https://web.archive.org/web/20220121085235fw_/https://www.caam.rice.edu/software/ARPACK/SRC/patch.tar.Z";
my $arpack_dir = "/usr/local/ARPACK";

if($wgetORgit eq "yes"){
    `rm -rf $packageDir/arpack`;
    `mkdir -p $packageDir/arpack`;
    chdir "$packageDir/arpack";    
    system("wget $arpack_url");
    `rm -rf  $arpack_dir`;
    `mkdir -p  $arpack_dir`;
    system("tar -xvf arpack96.tar.Z -C $arpack_dir --strip-components=1");
}
chdir ("$arpack_dir");
system("sed -i 's|home = .*|home = /usr/local/ARPACK|' ARmake.inc");
system("sed -i 's|PLAT = .*|PLAT = INTEL|' ARmake.inc");
system("sed -i 's|FC .*|FC = gfortran|' ARmake.inc");
system("sed -i 's|FFLAGS	= -O -cg89|FFLAGS = -O|' ARmake.inc");
system("make clean");
system("make lib");
chdir("$script_CurrentPath");

###end of ARPACK installation

#
## Download and install CalculiX 2.21
#my $calculix_url = "https://www.dhondt.de/ccx_2.21.src.tar.bz2";
#my $calculix_tar = "ccx_2.21.src.tar.bz2";
#my $calculix_dir = "/usr/local/CalculiX";
#my $calculix_src = "/usr/local/CalculiX/ccx_2.21/src/";
##
#if($wgetORgit eq "yes"){
#    `rm -rf $packageDir/Calculix`;
#    `mkdir -p $packageDir/Calculix`;
#    chdir "$packageDir/Calculix";
#    system("wget $calculix_url -O $calculix_tar");
#    `rm -rf /usr/local/CalculiX`;
#    `mkdir -p /usr/local/CalculiX`;
#    system("tar -xjf $calculix_tar -C /usr/local --strip-components=1");
#}
#
#chdir "$calculix_src";
#system("make -j 4"); # Adjust -j parameter based on your CPU cores for parallel compilation
#
## Check if CalculiX compiled successfully
#if (-e "ccx_2.21") {
#    print "CalculiX installed successfully.\n";
#} else {
#    die "Failed to compile CalculiX.\n";
#}
#
## Optionally, move the binary to a system-wide accessible location
## system("mv ccx_2.21 /usr/local/bin/");
#