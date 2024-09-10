=Developed by Prof. Shin-Pon Ju at NSYSU Oct.09 2020
https://brandonrozek.com/blog/openmpi-fedora/

openfoam.repo

dnf install openmpi openmpi-devel -y
source /etc/profile.d/modules.sh
module load mpi/openmpi-x86_64

1. Perl script to compile and install OpenFOAM with MPICH.

https://www.youtube.com/watch?v=eqvsRfnXgA4&list=PLgGLFqbLZQNFMeH7-zD-CUkNcEDUsNl34&index=6

install wget to download packages
yum search wget
yum list wget
yum info wget
sudo yum -y install wget

vim useful to look at log files in case something goes wrong
sudo yum -y install vim

work in a project folder
mkdir projects
cd projects

download OpenFOAM source code and third party libraries
wget https://sourceforge.net/projects/open...
tar zxvf OpenFOAM-v2212.tgz
rm -f OpenFOAM-v2212.tgz
wget https://sourceforge.net/projects/open...
tar zxvf ThirdParty-v2212.tgz
rm -f ThirdParty-v2212.tgz

install a basic gcc compiler
sudo yum -y install gcc
gcc --version

gcc 5.4 or higher is required for OpenFOAM, therefore install gcc 7
sudo yum install -y centos-release-scl
sudo yum install -y devtoolset-7
scl enable devtoolset-7 bash

scl enable command must be executed 
every time you want to compile code

install flex
sudo yum makecache
sudo yum -y install flex

install cmake
sudo yum install cmake

install QT
sudo yum install mesa-libGL-devel mesa-libGLU-devel
sudo yum install qt
sudo yum install qt-creator

install git
sudo yum install git

install OpenMPI
sudo yum install openmpi-devel
module load mpi

module load mpi
every time you want to compile and
every time you want to run parallel simulations

install zlib
sudo yum -y install zlib-devel

compile third party software and openfoam
source ~/projects/OpenFOAM-v2212/etc/bashrc

source ~/projects/OpenFOAM-v2212/etc/bashrc
every time you want to run a simulation
or compile code

cd projects/ThirdParty-v2212/
./Allwmake -j 8
./makeParaView
wmRefresh
cd ~/projects/OpenFOAM-v2212
./Allwmake -j 8

run tutorial
mkdir -p $FOAM_RUN
cd $FOAM_RUN
cp -r $FOAM_TUTORIALS/incompressible/simpleFoam/pitzDaily .
cd pitzDaily
blockMesh
simpleFoam

run tutorial
=cut

#export PATH=$PATH:/opt/mpich-4.0.3/bin
#export LD_LIBRARY_PATH=/opt/mpich-4.0.3/lib


sub path_setting{
	my $attached_path = shift;	
	my $path = $ENV{'PATH'};
	$ENV{'PATH'} = "$attached_path:$path";
}
	
sub ld_setting {
    my $attached_ld = shift;
	my $ld_library_path = $ENV{'LD_LIBRARY_PATH'};	
	$ENV{'LD_LIBRARY_PATH'} = "$attached_ld:$ld_library_path";		
}

sub include_setting {
    my $attached_include = shift;
	my $include_path = $ENV{'INCLUDE'};	
	$ENV{'INCLUDE'} = "$attached_include:$include_path";		
}

sub cpath_setting {
    my $attached_cpath = shift;
	my $c_path = $ENV{'CPATH'};	
	$ENV{'CPATH'} = "$attached_cpath:$c_path";		
}

my $mattached_path = "/opt/mpich-4.0.3/bin";#attached path in main script
path_setting($mattached_path);

my $mattached_ld = "/opt/mpich-4.0.3/lib";#attached ld path in main script
ld_setting($mattached_ld);

my $mattached_include = "/opt/mpich-4.0.3/include";#attached ld path in main script
include_setting($mattached_include);

my $mattached_cpath = "/opt/mpich-4.0.3/include";#attached ld path in main script
cpath_setting($mattached_cpath);


#export INCLUDE=/usr/lib64/openmpi/include:$INCLUDE
#export CPATH=/usr/lib64/openmpi/include:$CPATH
# export LD_LIBRARY_PATH=/usr/lib64/openmpi/lib:$LD_LIBRARY_PATH
#export PATH=/usr/lib64/openmpi/bin:$PATH 
# export MANPATH=/usr/lib64/openmpi/share:$MANPATH
#!/bin/sh
use warnings;
use strict;
use Cwd; #Find Current Path

#system("dnf install -y gcc gcc-c++ flex bison cmake make wget git zlib-devel" .
#   " boost-devel gmp-devel mpfr-devel python3-devel environment-modules qt5-qtbase-devel");

my $wgetORgit = "no";## if you want to download the source, use yes. set no, if you have downloaded the source.

my $packageDir = "/home/packages";
if (!-e $packageDir) { # if no /home/packages, make this folder
    system("mkdir $packageDir");
}

my $prefix = "/opt/openfoam";
my $package = "openfoam";
my $currentVer = "OpenFOAM-12";#***** the latest version of this package (check the latest one if possible)
my $thirdparty_fold = "ThirdParty-12";#***** the latest version of this package (check the latest one if possible)
#my $unzipFolder = "OpenFOAM-12";#***** the unzipped folder of this package (check the latest one if possible)
my $URL = "https://github.com/OpenFOAM/OpenFOAM-12.git";#url to download
my $URL_thirdparty = "https://github.com/OpenFOAM/ThirdParty-12.git";#url to download
my $Dir4download = "$packageDir/openfoam_download"; #the directory we download OpenFOAM
my $source = "source $Dir4download/$currentVer/etc/bashrc";
#https://github.com/OpenFOAM/ThirdParty-12.git
my $script_CurrentPath = getcwd(); #get perl code path

chdir("$script_CurrentPath");# cd to this dir for downloading the packages
if ($wgetORgit eq "yes") {
    system("rm -rf $Dir4download"); # remove the older directory first
    system("mkdir $Dir4download"); # make a directory in current path

    ##download openfoam
    chdir("$Dir4download"); # cd to this dir for downloading the packages
    ##get the latest package in the directory and save it as the filename you want
    system("git clone $URL"); # download openfoam
    system("git clone $URL_thirdparty"); # download openfoam
    #if ($?) { die "wget $URL failed!!\n"; }
    chdir("$script_CurrentPath");
}

chdir("$Dir4download/$thirdparty_fold"); # cd to this dir for downloading the packages
system("./Allclean");
system("$source && ./Allwmake");

#if (!-d "$Dir4download/$unzipFolder") {
#    die "No $unzipFolder folder after tar! You need to find the correct folder name\n";
#}
#
#chdir("$Dir4download/$unzipFolder"); # cd to this dir for downloading the packages
#my $date = `date +%Y%m%d`;
#
#my $prefix4OpenFOAM = "--prefix=$prefix";
#system("rm -rf $prefix");
#
## find all threads to make this package
#my $thread4make = `lscpu|grep "^CPU(s):" | sed 's/^CPU(s): *//g'`;
#print "Total threads can be used for make: $thread4make\n";
#
## Set MPI environment variables explicitly
#$ENV{'WM_MPLIB'} = 'SYSTEMMPI';
#$ENV{'MPI_ARCH_PATH'} = '/opt/mpich-4.0.3';
#$ENV{'FOAM_MPI'} = 'mpich';
#
## Source the OpenFOAM environment from the extracted source directory
#system("source $Dir4download/$unzipFolder/etc/bashrc");
#
## Ensure the correct PATH and LD_LIBRARY_PATH are set
#$ENV{'PATH'} = "$Dir4download/$unzipFolder/wmake:$ENV{'PATH'}";
#$ENV{'LD_LIBRARY_PATH'} = "$Dir4download/$unzipFolder/lib:$ENV{'LD_LIBRARY_PATH'}";
#
## Verify the presence of wmkdep
#if (! -x "$Dir4download/$unzipFolder/wmake/platforms/linux64Gcc/wmkdep") {
#    die "wmkdep not found in expected directory\n";
#}
#
#my $OpenFOAM_inst = "./Allwmake -j $thread4make";
#print "\$OpenFOAM_inst: $OpenFOAM_inst";
#system("$OpenFOAM_inst");
#if ($?) { die "**OpenFOAM build fails!\nReason:$?\n"; }
#
#print "OpenFOAM has been successfully installed!!\n";
#print "\n\nCheck installation in $prefix\n\n";
#system("ls $prefix");
