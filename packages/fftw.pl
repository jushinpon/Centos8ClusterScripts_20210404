#developed by Prof. Shin-Pon Ju (2021/Nov/1)
#Perl script to Downlaod and install fftw 
# You need to be root to use this script
#1. You need go to http://www.fftw.org/ to check the latest fftw version 

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

my $wgetORgit = "yes";

my $packageDir = "/home/packages";
if(!-e $packageDir){# if no /home/packages, make this folder	
	system("mkdir $packageDir");	
}

my $thread4make = `lscpu|grep "^CPU(s):" | sed 's/^CPU(s): *//g'`;
chomp $thread4make;
print "Total threads can be used for make: $thread4make\n";

#install fftw
my $URL = "http://www.fftw.org/fftw-3.3.10.tar.gz";#url to download
my $Dir4download = "$packageDir/fftw_download"; #the directory we download Mpich
my $currentPath = getcwd(); #get perl code path
####### in the directory of $lammps_download
if($wgetORgit eq "yes"){
	system ("rm -rf $Dir4download");# remove the older directory first
	system("mkdir -p $Dir4download");# make a directory in current path
	
	chdir("$Dir4download");# cd to this dir for downloading the packages
	#system("git clone $URL lammps");
	system("wget $URL");
    my $temp = `ls *`;# currently only one file in this dir
    chomp $temp;
    print "file by wget: $temp\n";    
	system("tar xvzf $temp");
    $temp = `find ./ -maxdepth 1 -mindepth 1 -type d -name "*"|awk -F'/' '{print \$NF}'`;
    chomp $temp;
    print "Folder name after tar: $temp\n";
	chdir("$Dir4download/$temp");
	#system("make clean");

	system("./configure --prefix=/opt/fftw");
	system("make -j $thread4make");
	system("make install");

	#system("git checkout tags/stable_3Mar2020 -b stable");#user-bigwind ok
	##system("git checkout tags/stable_29OctMar2020 -b stable");#user-bigwind bad

## copy our packages here

}
#--prefix=/opt/fftw;
#chdir("$currentPath");# cd to this dir for downloading the packages


#chdir("$Dir4download/lammps/src");
#	system ("make -j $thread4make mpi");####**** check how many cores you may use for compiling lammps
	#print ""
	
print "*******FFTW DONE!\n";
