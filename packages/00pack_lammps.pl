#Perl script to Downlaod and install lammps developed by Prof. Shin-Pon Ju (2019/Oct/31)
# You need to be root to use this script
#1. You need go to http://lammps.sandia.gov/tars/lammps.tar.gz to check the latest lammps version and set the downloading url
#2. compiling procedure
#a. make a directory to download the tar.gz file 
#b. get the source zip file and rename it as lammps file (wget -O lammps XXX)
#c. unziptar -xvzf
#d.do the necessary things
#e. if you get c11 problem, do "CCFLAGS =	-g -O3 -std=c++11" setting in Makefile.mpi, also add -fopenmp for gcc 

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
my $mattached_path = "/opt/mpich-3.3.2/bin";#attached path in main script
path_setting($mattached_path);
my $mattached_ld = "/opt/mpich-3.3.2/lib";#attached ld path in main script
ld_setting($mattached_ld);
use Cwd; #Find Current Path
#use FindBin; #Find Path
use File::Copy; # Copy File
#use Env::Modify qw(:sh source);

#my @GCC_Version = (7,8); # GCC versions have been installed in "/opt/rh/" 
#my $mpichPath = "/opt/mpich-3.3.2_GCC";
$thread4make = 8; # the thread number used for make !!!!!!!	

open Check, ">00lammpsInstall_Status.txt";
print Check "===========Process status (0 is ok): sysytem call purpose============\n";

$URL = "https://github.com/lammps/lammps.git";#url to download
$Dir4download = "lammps_download"; #the directory we download Mpich

$script_CurrentPath = getcwd; #get perl code path

####### in the directory of $lammps_download
#system ("rm -rf $Dir4download");# remove the older directory first
#system("mkdir $Dir4download");# make a directory in current path
print "current path: $script_CurrentPath\n";
chdir("$script_CurrentPath/$Dir4download");# cd to this dir for downloading the packages
#get the latest package in the directory and save it as the filename you want
#$Ch = system("wget -O lammps $URL"); 
#$Ch = system("git clone $URL");

print Check "$Ch:wget -O lammps or git clone $URL\n";

$tar_path = getcwd;# get the current path and then unzip the lammps from wget -O

# tar -xvzf XXX(package name), and then cd this new folder	
#$Ch = system("tar -xvzf lammps"); #$Ch =  Check
#print Check "$Ch: tar -xvzf lammps\n";	
#if($Ch != 0){die "tar process failed!\n";}

#@temp = `ls $tar_path`; #get the name of a folder (we just unzip)
#foreach (@temp){
#	chomp;
#	if(-d $_ ){	$source_folder = $_;}# get the folder name (after tar, we will get a directory)
#}
### do some settings before make (make sure the one or ones you want to modify first!!!!)
#system("perl -p -i.bak -e 's/#define maxelt.+/#define maxelt 10/;' $script_CurrentPath/$Dir4download/lammps/src/USER-MEAMC/meam.h");
#system("perl -p -i.bak -e 's/CCFLAGS\\s+=.+/CCFLAGS = -g -O3 -std=c++11 -fopenmp/;' $script_CurrentPath/$Dir4download/lammps/src/MAKE/Makefile.mpi");
#system("perl -p -i.bak -e 's/LINKFLAGS\\s+=.+/LINKFLAGS = -g -O3 -fopenmp/;' $script_CurrentPath/$Dir4download/lammps/src/MAKE/Makefile.mpi");

chdir("$script_CurrentPath/$Dir4download/lammps/src");


	system ("make no-all");# uninstall all packages at the very beginning
	#system ("make all");# install all packages at the very beginning
	system ("make clean"); # clean all old object files
	# the first three are the basic packages
	@lmp_package= ("kspace","manybody","molecule","user-meamc","user-misc","user-omp","rigid","misc","dipole","replica","user-bigwind");
	# You need to check lammps web about the package lib if needed.

	foreach $installpack (@lmp_package){	
		system ("make yes-$installpack");	#make this package installed
	}

	system ("make clean"); # clean all old object files
	unlink ("lmp_mpi");#remove all old lmp executable

	$Ch = system ("make -j $thread4make mpi");####**** check how many cores you may use for compiling lammps
	##lmp_mpi is in src
	$datformat='+%Y%m%d';
	$getdat ="date"." $datformat ";
	$test=`$getdat`;
	$lmp_path = "/opt/lammps"."/lmp"."_mpiGCC$GV"."_$test";### make date information

	if(-e "/opt/lammps" and -d "/opt/lammps" ){
	system ("cp lmp_mpi $lmp_path");
	}
	else{
	system("mkdir /opt/lammps");
	system ("cp lmp_mpi $lmp_path");
	}
#system("rm -rf /opt/lammps");
print "*******LAMMPS EXECUTABLE DONE!\n";
