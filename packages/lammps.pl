#Perl script to Downlaod and install lammps developed by Prof. Shin-Pon Ju (2019/Oct/31)
# You need to be root to use this script
#1. You need go to http://lammps.sandia.gov/tars/lammps.tar.gz to check the latest lammps version and set the downloading url
#2. compiling procedure
#a. make a directory to download the tar.gz file 
#b. get the source zip file and rename it as lammps file (wget -O lammps XXX)
#c. unziptar -xvzf
#d.do the necessary things
#e. if you get c11 problem, do "CCFLAGS =	-g -O3 -std=c++11" setting in Makefile.mpi, also add -fopenmp for gcc 

#https://docs.lammps.org/Packages_details.html
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
##my $mattached_ld = "/opt/openmpi-4.1.0/lib";#attached ld path in main script
#my $mattached_ld = "/opt/mvapich2-2.3.5-srunMrail/lib";#attached ld path in main script
#ld_setting($mattached_ld);

use warnings;
use strict;
use Cwd; #Find Current Path
#use FindBin; #Find Path
use File::Copy; # Copy File
#use Env::Modify qw(:sh source);

my $wgetORgit = "no";

my $packageDir = "/home/packages";
if(!-e $packageDir){# if no /home/packages, make this folder	
	system("mkdir $packageDir");	
}

my $thread4make = `lscpu|grep "^CPU(s):" | sed 's/^CPU(s): *//g'`;
chomp $thread4make;
print "Total threads can be used for make: $thread4make\n";

my $URL = "https://github.com/lammps/lammps.git";#url to download
#my $URL = "https://lammps.sandia.gov/tars/lammps.tar.gz";#url to download
my $Dir4download = "$packageDir/lammps_download"; #the directory we download Mpich
my $currentPath = getcwd(); #get perl code path

##lmp_mpi will be in src
	my $datformat='+%Y%m%d';
	my $getdat ="date"." $datformat ";
	my $test=`$getdat`;
	chomp $test;
	my $lmp_exe = "/opt/lammps-mpich-3.4.2"."/lmp"."_$test";### make date information
	my $lmp_exeDir = "/opt/lammps-mpich-3.4.2/";### make date information
    #my $lmp_exe = "/opt/lammps-mpich-3.4.2-bigwind"."/lmp"."_$test";### make date information
	#my $lmp_exeDir = "/opt/lammps-mpich-3.4.2-bigwind/";### make date information
    
	#my $lmp_exe = "/opt/lammps-openmpi-4.1.0"."/lmp"."_$test";### make date information
	#my $lmp_exeDir = "/opt/lammps-openmpi-4.1.0/";### make date information
    #my $lmp_exe = "/opt/lammps-mvapich-2.3.5_srunMrail"."/lmp"."_$test";### make date information
	#my $lmp_exeDir = "/opt/lammps-mvapich-2.3.5_srunMrail/";### make date information

####### in the directory of $lammps_download
if($wgetORgit eq "yes"){
	system ("rm -rf $Dir4download");# remove the older directory first
	system("mkdir $Dir4download");# make a directory in current path
	
	chdir("$Dir4download");# cd to this dir for downloading the packages
	system("git clone $URL lammps");
	#system("wget -O lammps $URL");
	#system("tar xvzf lammps");
	#chdir("$Dir4download/lammps");# cd to this dir for downloading the packages
	#system("git checkout tags/stable_3Mar2020 -b stable");#user-bigwind ok
	##system("git checkout tags/stable_29OctMar2020 -b stable");#user-bigwind bad

## copy our packages here

}

#chdir("$currentPath");# cd to this dir for downloading the packages

system("rm -rf  $Dir4download/lammps/src/USER-BIGWIND");
system("cp -fR ./USER-BIGWIND $Dir4download/lammps/src");
if($?){die "Can't copy user-bigwind into lammps/src\n"}
#### do some settings before make (make sure the one or ones you want to modify first!!!!)
system("perl -p -i.bak -e 's/#define maxelt.+/#define maxelt 12/;' $Dir4download/lammps/src/MEAM/meam.h");
#system("cat $Dir4download/lammps/src/MEAM/meam.h|grep  '#define maxelt'");
system("perl -p -i.bak -e 's/CCFLAGS\\s+=.+/CCFLAGS = -g -O3 -std=c++11 -fopenmp/;' $Dir4download/lammps/src/MAKE/Makefile.mpi");
system("perl -p -i.bak -e 's/LINKFLAGS\\s+=.+/LINKFLAGS = -g -O3 -fopenmp/;' $Dir4download/lammps/src/MAKE/Makefile.mpi");

chdir("$Dir4download/lammps/src");
	#system("make lib-voronoi args='-b -v voro++0.4.6'");#make voro++ lib first
	#if($?){die"make voro++ lib failed!\n";}#,"voronoi"
	system ("make no-all");# uninstall all packages at the very beginning
	#system ("make all");# install all packages at the very beginning
	system ("make clean-all"); # clean all old object files
	# the first three are the basic packages
	#my @lmp_package= ("EXTRA-FIX","EXTRA-MOLECULE","EXTRA-COMPUTE","EXTRA-DUMP",
	#"EXTRA-PAIR","class2","kspace","manybody","molecule","meam","misc","openmp","rigid","dipole","replica","shock","yaff","molfile","mc");
	#for bigwind only
	my @lmp_package= ("kspace","manybody","molecule","user-meamc","user-misc","user-omp","rigid","misc","dipole","replica","user-bigwind");
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
