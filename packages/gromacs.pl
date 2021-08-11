#Perl script to Downlaod and install gromacs (developed by Prof. Shin-Pon Ju (2021/Mar/01))
# You need to be root to use this script
#1. You need go to https://github.com/gromacs/gromacs to check the latest gromacs situation
#2. you need to install the latest cmake for configuring your system.(use cmake.pl)
#a. make a directory to download the tar.gz or git clone files 
#b. get the source zip file and rename it as lammps file (wget -O lammps XXX)
#c. unziptar -xvzf
#d.do the necessary things

####set environment variables for path and lib (only works in this script)
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

#my $mattached_path = "/opt/mpich-3.3.2/bin";#attached path in main script
my $mattached_path = "/opt/mpich-3.4.2/bin";#attached path in main script
path_setting($mattached_path);#:/opt/intel/mkl/lib/intel64
#my $mattached_ld = "/opt/mpich-3.3.2/lib";#attached ld path in main script
my $mattached_ld = "/opt/mpich-3.4.2/lib";#attached ld path in main script
ld_setting($mattached_ld);

#my $mattached_path = "/opt/openmpi-4.1.0/bin";#attached path in main script
#my $mattached_path = "/opt/mvapich2-2.3.5-srunMrail/bin";#attached path in main script
#path_setting($mattached_path);#:/opt/intel/mkl/lib/intel64
#my $mattached_ld = "/opt/openmpi-4.1.0/lib";#attached ld path in main script
#my $mattached_ld = "/opt/mvapich2-2.3.5-srunMrail/lib";#attached ld path in main script
#ld_setting($mattached_ld);

use warnings;
use strict;
use Cwd; #Find Current Path
#use Env::Modify qw(:sh source);
#system("dnf install cmake -y");
my $wgetORgit = "yes";
my $prefix = "/opt/gromacs_MPICH3.4.2";
my $packageDir = "/home/packages";
if(!-e $packageDir){# if no /home/packages, make this folder	
	system("mkdir $packageDir");	
}

my $thread4make = `lscpu|grep "^CPU(s):" | sed 's/^CPU(s): *//g'`;
chomp $thread4make;
print "Total threads can be used for make: $thread4make\n";

my $URL = "https://github.com/gromacs/gromacs.git";#url to download
my $Dir4download = "$packageDir/gromacs_download"; #the directory we download Mpich
my $currentPath = getcwd(); #get perl code path

##get GROMACS by wget (not work now!)
#$GROMACS_URL = "http://ftp.gromacs.org/pub/gromacs/gromacs-5.1.5.tar.gz";
#system("wget -O gromacs-5.1.5.tar.gz $GROMACS_URL");
#system("tar xfz gromacs-5.1.5.tar.gz");
#chdir("gromacs-5.1.5");
#mkdir("build");
#chdir("build");
if($wgetORgit eq "yes"){
	system ("rm -rf $Dir4download");# remove the older directory first
	system("mkdir $Dir4download");# make a directory in current path
	chdir("$Dir4download");# cd to this dir for downloading the packages
	system("git clone $URL");	
	chdir("$currentPath");# cd to this dir for downloading the packages
}

chdir("$Dir4download/gromacs");# cd to this dir
system ("rm -rf build");# remove the older directory first
system("mkdir build");
chdir("$Dir4download/gromacs/build");# cd to this dir 
system("cmake .. -DGMX_BUILD_OWN_FFTW=ON -DREGRESSIONTEST_DOWNLOAD=ON -DGMX_GPU=off -DGMX_MPI=on -DCMAKE_INSTALL_PREFIX=$prefix");
system("make -j 8");
system("make check");
system("make install");
system(". $prefix/bin/GMXRC");

#if(!`grep 'export PATH=/usr/local/gromacs/bin:\$PATH' /etc/profile`){
#`echo 'export PATH=/usr/local/gromacs/bin:\$PATH' >> /etc/profile`;
#}
#print"######################\nPlease reboot\n######################\n";
