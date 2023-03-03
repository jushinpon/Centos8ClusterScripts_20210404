#Perl script to Downlaod deepMD source and then make USER-DEEPMD module (perl script developed by Prof. Shin-Pon Ju)
#https://docs.deepmodeling.com/projects/deepmd/en/master/install/install-from-source.html
#git clone --recursive https://github.com/deepmodeling/deepmd-kit.git deepmd-kit
#cd ./deepmd-kit/source/install, python ./build_tf.py (need superlarge ram, over 35G for compiling, need chmod 755 -R /opt/tf)
#maybe you need to install cmake first, build build under source folder

#cmake -DTENSORFLOW_ROOT=/opt/tf -DCMAKE_INSTALL_PREFIX=/home/packages/deepMD/deepmd-kit ..
#make lammps
#
#you will get USER-DEEPMD
use warnings;
use strict;
use Env::Modify qw(:sh source);
use Cwd; #Find Current Path
use File::Copy; # Copy File

my $wgetORgit = "no";

my $packageDir = "/home/packages";
if(!-e $packageDir){# if no /home/packages, make this folder	
	system("mkdir $packageDir");	
}

my $current_path = getcwd();# get the current path dir

# find all threads to make this package
my $thread4make = `lscpu|grep "^CPU(s):" | sed 's/^CPU(s): *//g'`;
chomp $thread4make;
print "Total threads can be used for make: $thread4make\n";
my $Dir4download = "$packageDir/deepMD"; #the directory we download MPICH

if($wgetORgit eq "yes"){
	system ("rm -rf $Dir4download");# remove the older directory first
	system("mkdir $Dir4download");# make a directory in current path
	
	chdir("$Dir4download");# cd to this dir for downloading the packages
	system("git clone --recursive https://github.com/deepmodeling/deepmd-kit.git deepmd-kit");
}
###
system("rm -rf $Dir4download/deepmd-kit/source/build");
system("mkdir -p $Dir4download/deepmd-kit/source/build");
`rm -rf /opt/deepmd_lammpslib`;
`mkdir -p /opt/deepmd_lammpslib`;
chdir("$Dir4download/deepmd-kit/source/build");# cd to this dir for downloading the packages -DLAMMPS_SOURCE_ROOT=/home/packages/lammps_deepMD/lammps-23Jun2022/ 
system("cmake -DTENSORFLOW_ROOT=/opt/tf -DCMAKE_INSTALL_PREFIX=/opt/deepmd_lammpslib/ ..");# -DUSE_CUDA_TOOLKIT=TRUE ..
system("make -j $thread4make");
system("make install");
`rm -rf USER-DEEPMD`;
system("make lammps");
chdir("$Dir4download/deepmd-kit");# cd to this dir for downloading the packages
print "\n***ls /opt/deepmd_lammpslib\n\n";
system("ls /opt/deepmd_lammpslib");
#/home/packages/deepMD/deepmd-kit/source/build/USER-DEEPMD
print "\n***ls $Dir4download/deepmd-kit/source/build/USER-DEEPMD\n";
system("ls $Dir4download/deepmd-kit/source/build/USER-DEEPMD");
#system("make lammps");
#die "No USER-DEEPMD in $Dir4download/deepmd-kit/source/build \n" unless (`ls USER-DEEPMD`);