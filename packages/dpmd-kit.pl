=b
1. you need to install anaconda first: check https://www.anaconda.com/products/individual#linux 
2. cd /opt; wget https://repo.anaconda.com/archive/Anaconda3-2021.05-Linux-x86_64.sh;
3. ./ana...
4. installation path /opt/anaconda3
5. source activate
6. conda create --name dpmd-kit-cpu
7.conda info --envs
8. conda activate dpmd-kit-cpu
9. conda install deepmd-kit=*=*cpu lammps-dp=*=*cpu -c deepmodeling

5. source conda activate dpmd-kit_CPU 
#Perl script to Downlaod and install dpmd-kit (developed by Prof. Shin-Pon Ju (2021/Apr/06))
# You need to be root to use this script and install Anaconda under /opt first, and check the following web:
#https://deepmd.readthedocs.io/en/master/install.html
=cut
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


#my $mattached_path = "/opt/openmpi-4.1.0/bin";#attached path in main script
my $mattached_path = "/opt/mvapich2-2.3.5-srunMrail/bin";#attached path in main script
path_setting($mattached_path);#:/opt/intel/mkl/lib/intel64
#my $mattached_ld = "/opt/openmpi-4.1.0/lib";#attached ld path in main script
my $mattached_ld = "/opt/mvapich2-2.3.5-srunMrail/lib";#attached ld path in main script
ld_setting($mattached_ld);

use warnings;
use strict;
use Cwd; #Find Current Path
#use FindBin; #Find Path
use File::Copy; # Copy File

my $wgetORgit = "yes";

my $packageDir = "/home/packages";
if(!-e $packageDir){# if no /home/packages, make this folder	
	system("mkdir $packageDir");	
}

my $thread4make = `lscpu|grep "^CPU(s):" | sed 's/^CPU(s): *//g'`;
chomp $thread4make;
print "Total threads can be used for make: $thread4make\n";

my $URL = "https://github.com/deepmodeling/deepmd-kit.git";#url to download
#my $URL = "https://lammps.sandia.gov/tars/lammps.tar.gz";#url to download
my $Dir4download = "$packageDir/dpmdKit_download"; #the directory we download Mpich
my $currentPath = getcwd(); #get perl code path

##lmp_mpi will be in src
	my $datformat='+%Y%m%d';
	my $getdat ="date"." $datformat ";
	my $test=`$getdat`;
	chomp $test;
	
####### in the directory of $lammps_download
if($wgetORgit eq "yes"){
	system ("rm -rf $Dir4download");# remove the older directory first
	system("mkdir $Dir4download");# make a directory in current path
	
	chdir("$Dir4download");# cd to this dir for downloading the packages
	system("git clone --recursive $URL deepmd-kit");
	chdir("$currentPath");# cd to this dir for downloading the packages
	
}

chdir("$Dir4download");

	system ("make no-all");# uninstall all packages at the very beginning
	#system ("make all");# install all packages at the very beginning
	system ("make clean-all"); # clean all old object files
	# the first three are the basic packages
	my @lmp_package= ("class2","kspace","manybody","molecule","user-meamc","user-misc","user-omp","rigid","misc","dipole","replica","user-bigwind");
	# You need to check lammps web about the package lib if needed.

	foreach my $installpack (@lmp_package){	
		system ("make yes-$installpack");	#make this package installed
	}

	system ("make clean"); # clean all old object files
	unlink ("lmp_mpi");#remove all old lmp executable

	system ("make -j $thread4make mpi");####**** check how many cores you may use for compiling lammps
	#print ""
	if(-e "$lmp_exeDir" and -d "$lmp_exeDir" ){
		unlink $lmp_exe;
		system ("cp lmp_mpi $lmp_exe");
	}
	else{
		system("mkdir $lmp_exeDir");
		system ("cp lmp_mpi $lmp_exe");
	}
	system("chmod -R 755  $packageDir");
	
print "*******LAMMPS EXECUTABLE DONE!\n";
