#mklpath = /opt/intel/oneapi/mkl/2025.0
#export PATH=$PATH:/path/to/vasp.x.x.x/bin
#export LD_LIBRARY_PATH=/opt/hdf5/lib:$LD_LIBRARY_PATH
#ldd /opt/vasp/bin/vasp_std

#MUST　ＤＯ：
#source /opt/intel/oneapi/setvars.sh

#wget https://support.hdfgroup.org/ftp/HDF5/current/src/hdf5-1.14.3.tar.gz

#wget https://support.hdfgroup.org/releases/hdf5/v1_14/v1_14_6/downloads/hdf5-1.14.6.tar.gz

#tar -xzf hdf5-1.14.3.tar.gz
#cd hdf5-1.14.3
#./configure --prefix=/opt/hdf5 --enable-fortran --enable-parallel
#make -j$(nproc)
#sudo make install

#https://github.com/HDFGroup/hdf5.git
#https://www.hdfgroup.org/download-hdf5/source-code/#

#!/usr/bin/perl
use strict;
use warnings;
use Cwd qw/getcwd abs_path/;
use POSIX qw(strftime);

my $script_CurrentPath = getcwd(); #get perl code path

my $wgetORgit = "yes";## if you want to download the source, use yes. set no, if you have downloaded the source.

my $packageDir = "/home/packages";
if(!-e $packageDir){# if no /home/packages, make this folder	
	system("mkdir $packageDir");	
}

my $prefix = "/opt/hdf5";
my $package = "hdf5";
my $currentVer = "hdf5-1.14.6.tar.gz";#***** the latest version of this package (check the latest one if possible)
my $unzipFolder = "hdf5-1.14.6";#***** the unzipped folder of this package (check the latest one if possible)
my $URL = "https://support.hdfgroup.org/releases/hdf5/v1_14/v1_14_6/downloads/hdf5-1.14.6.tar.gz";#url to download
my $Dir4download = "$packageDir/hdf5_download"; #the directory we download Mpich


chdir("$script_CurrentPath");# cd to this dir for downloading the packages
if($wgetORgit eq "yes"){
	system("rm -rf $Dir4download");# remove the older directory first
	system("mkdir $Dir4download");# make a directory in current path

##download qe and thermo_pw
	chdir("$Dir4download");# cd to this dir for downloading the packages
##get the latest package in the directory and save it as the filename you want
	system("wget $URL"); # download qe
	if($?){die "wget $URL failed!!\n";} 
} 

chdir("$Dir4download");# cd to this dir for downloading the packages

system("rm -rf $unzipFolder");
system("tar xvzf $currentVer");
if($?){die "tar xvzf $currentVer failed!!\n";} 

if(! -d "$Dir4download/$unzipFolder" ){
	die "No $unzipFolder folder after tar! You need to find the correct folder name\n";
}


chdir("$Dir4download/$unzipFolder");# cd to this dir for downloading the packages
my $date=`date +%Y%m%d`;

my $prefix4hdf5 = "--prefix=$prefix";
system("rm -rf $prefix");

my $thread4make = `nproc`;
chomp $thread4make;
print "Total threads can be used for make: $thread4make\n";

#after the configure process is done, type "make" and then "make install"
#system("make distclean"); 
if($?){die "**make hdf5 clean fails";}

system("./configure", "--prefix=/opt/hdf5", "--enable-fortran", "--enable-parallel");

print "$thread4make";
system("make -j $thread4make");
if($?){die "make hdf5 failed!\nReason:$?\n";}
system("make install");
if($?){die "make install hdf5 failed!\n";}

print "hdf5 has been successfully installed!!\n";
print "\n\nCheck hdf5 in /opt/hdf5/bin!! \n\n";
system("ls $prefix/bin"); 
