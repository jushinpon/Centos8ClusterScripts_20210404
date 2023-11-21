#Perl script to Downlaod and install lammps+deepmd-kit developed by Prof. Shin-Pon Ju (2019/Oct/31)
#You need to be root to use this script
#check the follwoing link for the specific lammps version:
#https://docs.deepmodeling.com/projects/deepmd/en/master/install/install-lammps.html
#e. if you get c11 problem, do "CCFLAGS =	-g -O3 -std=c++11" setting in Makefile.mpi, also add -fopenmp for gcc 


#export LD_LIBRARY_PATH=/opt/lmp_deepmd_mpich4.0.3/lib:/opt/deepmd_lammpslib/lib:$LD_LIBRARY_PATH
#LAMMPS_PLUGIN_PATH=/opt/deepmd_lammpslib/lib/deepmd_lmp 

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
#my $mattached_path = "/opt/mpich-3.4.2/bin";#attached path in main script
my $mattached_path = "/opt/mpich-4.0.3/bin";#:/opt/deepmd_lammpslib/bin";#2023/01/27 (don't use deep lib link)
path_setting($mattached_path);#:/opt/intel/mkl/lib/intel64
#my $mattached_ld = "/opt/mpich-3.3.2/lib";#attached ld path in main script
#my $mattached_ld = "/opt/mpich-3.4.2/lib";#attached ld path in main script
my $mattached_ld = "/opt/mpich-4.0.3/lib";#:/opt/deepmd_lammpslib/lib";#2023/01/27
ld_setting($mattached_ld);
#/opt/anaconda3/envs/deepmd-cpuV203/include/deepmd/DeepPot.h
#/home/packages/deepMD/deepmd-kit/source/build/api_cc/version.h

use warnings;
use strict;
use Cwd; #Find Current Path
use File::Copy; # Copy File
`chmod -R 755 /opt/tf`;
my $wgetORgit = "yes";
#my $user_deep_dir = "/home/packages/deepMD/deepmd-kit/source/build/USER-DEEPMD"; #where you put USER-DEEPMD
my $prefix = "/opt/lmp_deepmd_mpich4.0.3";
`rm -rf /opt/lmp_deepmd_mpich4.0.3`;
my $deepMD_lib_dir = "/home/packages/deepMD/deepmd-kit";
my $packageDir = "/home/packages";
if(!-e $packageDir){# if no /home/packages, make this folder	
	system("mkdir $packageDir");	
}

my $thread4make = `nproc`;
chomp $thread4make;
print "Total threads can be used for make: $thread4make\n";
#wget https://github.com/lammps/lammps/archive/stable_23Jun2022_update2.tar.gz
#my $URL = "https://github.com/lammps/lammps/archive/stable_2Aug2023_update1.tar.gz";#url to download
my $URL = "https://github.com/lammps/lammps/archive/stable_23Jun2022_update2.tar.gz";#url to download
#my $URL = "https://lammps.sandia.gov/tars/lammps.tar.gz";#url to download
my $Dir4download = "$packageDir/lammps4deepmd"; #the directory we download Mpich
my $currentPath = getcwd(); #get perl code path
#my $lmp_path = "/home/packages/lammps4deepmd/lammps-stable_2Aug2023_update1";
my $lmp_path = "/home/packages/lammps4deepmd/lammps-stable_23Jun2022_update2";

##lmp_mpi will be in src
	my $datformat='+%Y%m%d';
	my $getdat ="date"." $datformat ";
	my $test=`$getdat`;
	chomp $test;
	my $lmp_exe = "/opt/lammps-mpich-4.0.3"."/lmpdeepmd"."_$test";### make date information
	my $lmp_exeDir = "/opt/lammps-mpich-4.0.3/";### make date information
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
	#system("git clone $URL lammps");
	system("wget -O lammps $URL");
	system("tar xvzf lammps");
	#/home/packages/lammps4deepmd/lammps-stable_23Jun2022_update2/
	#chdir("$Dir4download/lammps");# cd to this dir for downloading the packages
	#system("git checkout tags/stable_3Mar2020 -b stable");#user-bigwind ok
	##system("git checkout tags/stable_29OctMar2020 -b stable");#user-bigwind bad
	#die "******make deepmd lib first\n";
## copy our packages here

}

chdir("$currentPath");# cd to this dir for downloading the packages



#system("rm -rf  $Dir4download/lammps/src/USER-DEEPMD");
#system("cp -fR $user_deep_dir $Dir4download/lammps/src");
#if($?){die "Can't copy USER-DEEPMD into lammps/src\n"}
#### do some settings before make (make sure the one or ones you want to modify first!!!!)
system("perl -p -i.bak -e 's/#define maxelt.+/#define maxelt 12/;' $lmp_path/src/MEAM/meam.h");
#system("cat $Dir4download/lammps/src/MEAM/meam.h|grep  '#define maxelt'");
system("perl -p -i.bak -e 's/CCFLAGS\\s+=.+/CCFLAGS = -g -O3 -std=c++11 -fopenmp/;' $lmp_path/src/MAKE/Makefile.mpi");
system("perl -p -i.bak -e 's/LINKFLAGS\\s+=.+/LINKFLAGS = -g -O3 -fopenmp/;' $lmp_path/src/MAKE/Makefile.mpi");

chdir("$lmp_path/src");
`rm -rf USER-DEEPMD`;
system("cp -R /home/packages/deepMD/deepmd-kit/source/build/USER-DEEPMD ./");
if($?){die "No USER-DEEPMD in /home/packages/deepMD/deepmd-kit/source/build"}
#if($?){system("cp -R $currentPath/USER-DEEPMD ./");}

	system("make lib-voronoi args='-b -v voro++0.4.6'");#make voro++ lib first
	if($?){die"make voro++ lib failed!\n";}#,"voronoi"
	#system("make lib-plumed args='-b'");#make voro++ lib first
	#if($?){die"make plumed lib failed!\n";}#,"voronoi"

	system ("make no-all");# uninstall all packages at the very beginning
    system("make no-user-deepmd");
	#system ("make all");# install all packages at the very beginning
	system ("make clean-all"); # clean all old object files
#	# the first three are the basic packages
	my @lmp_package= ("EXTRA-FIX","EXTRA-MOLECULE","EXTRA-COMPUTE","EXTRA-DUMP","user-deepmd",
	"EXTRA-PAIR","class2","kspace","manybody","molecule","meam","misc","openmp","rigid","dipole","replica","shock","yaff","molfile","mc","phonon","coreshell","diffraction","voronoi");
#	#for bigwind only
#	#my @lmp_package= ("kspace","manybody","molecule","user-meamc","user-misc","user-omp","rigid","misc","dipole","replica","user-bigwind");
#	# You need to check lammps web about the package lib if needed.
#
	for my $installpack (@lmp_package){	
		system ("make yes-$installpack");	#make this package installed
	}
#
	system ("make clean-all"); # clean all old object files
	unlink ("lmp_mpi");#remove all old lmp executable
#
	system ("make -j $thread4make mpi");####**** check how many cores you may use for compiling lammps
#	die

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
