=Developed by Prof. Shin-Pon Ju at NSYSU (Feb.01 2021)

1. After mvapich installation, this script can then install osu_benchmark.
=cut

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
#my $mattached_path = "/opt/slurm_mvapich2-2.3.4/bin";#attached path in main script
my $mattached_path = "/opt/mvapich2-2.3.5-softRDMA/bin";#attached path in main script
path_setting($mattached_path);
#my $mattached_ld = "/opt/slurm_mvapich2-2.3.4/lib";#attached ld path in main script
my $mattached_ld = "/opt/mvapich2-2.3.5-softRDMA/lib";#attached ld path in main script
ld_setting($mattached_ld);

#!/bin/sh
use warnings;
use strict;
use Cwd; #Find Current Path

my $wgetORgit = "yes";# yes or no
my $packageDir = "/home/packages";
if(!-e $packageDir){# if no /home/packages, make this folder	
	system("mkdir $packageDir");	
}

my $currentPath = getcwd();# get the current path dir

# find all threads to make this package
my $thread4make = `lscpu|grep "^CPU(s):" | sed 's/^CPU(s): *//g'`;
chomp $thread4make;
print "Total threads can be used for make: $thread4make\n";
if($thread4make == 0){die "thread Number for make is $thread4make\n";}

my $URL = "https://mvapich.cse.ohio-state.edu/download/mvapich/osu-micro-benchmarks-5.7.tar.gz";
my $osuSource = "/home/packages/mvapich2-2.3.5-4slurm_download/mvapich2-2.3.5/osu_benchmarks";
my $currentVer = "osu-micro-benchmarks-5.7";#***** the latest version of this package
my $prefixPath = "/opt/$currentVer";
system ("rm -rf $prefixPath");# remove the older directory first
my $Dir4download = "$packageDir/$currentVer-download"; #the directory we download Mpich

#my $buildPath = "$packageDir/mvapich_download/$currentVer/osu_benchmarks"; #the directory we download MPICH

#
if($wgetORgit eq "yes"){
	system ("rm -rf $Dir4download");# remove the older directory first
	system("mkdir $Dir4download");# make a directory in current path
	
	chdir("$Dir4download");# cd to this dir for downloading the packages
	system("wget ");
	#system("wget -O lammps $URL");
	#system("tar xvzf lammps");
	chdir("$Dir4download/lammps");# cd to this dir for downloading the packages
	system("git checkout tags/stable_3Mar2020 -b stable");#user-bigwind ok
	#system("git checkout tags/stable_29OctMar2020 -b stable");#user-bigwind bad
	sleep(5);
	system("git pull");

## copy our packages here
#chdir("$currentPath");# cd to this dir for downloading the packages

	system("rm -rf  $Dir4download/lammps/src/USER-BIGWIND");
	system("cp -fR ./USER-BIGWIND $Dir4download/lammps/src");
	if($?){die "Can't copy user-bigwind into lammps/src\n"}
	#### do some settings before make (make sure the one or ones you want to modify first!!!!)
	system("perl -p -i.bak -e 's/#define maxelt.+/#define maxelt 10/;' $Dir4download/lammps/src/USER-MEAMC/meam.h");
	system("perl -p -i.bak -e 's/CCFLAGS\\s+=.+/CCFLAGS = -g -O3 -std=c++11 -fopenmp/;' $Dir4download/lammps/src/MAKE/Makefile.mpi");
	system("perl -p -i.bak -e 's/LINKFLAGS\\s+=.+/LINKFLAGS = -g -O3 -fopenmp/;' $Dir4download/lammps/src/MAKE/Makefile.mpi");
}


chdir("$osuSource");#$currentVer is the directory name after tar
system("make uninstall");
system("make clean all");
unlink "Makefile";
sleep(1);
#system("./configure --prefix=$prefixPath");# --with-slurm=[/usr/local] VERBOSE=1 |tee 00mpich_configure.txt"); #./configure
#if($?){die "config $currentVer failed!\nReason $?:$!\n";}

#die"configure completed\n";
#after the configure process is done, type "make" and then "make install"
system("make clean"); 
sleep(1);

system("make -j $thread4make |tee 00osu_make.txt"); 
if($?){die "make osu process failed!\n Reason $?:$!\n";}

system("make install |tee 00osu_makeInstall.txt");
if($?){die "make install osu failed!\nReason $?:$!\n";}

#system("chmod -R 755 $packageDir");# set the permission for all users

#system("perl -p -i.bak -e 's/.*mpich-.+\n//g;' /etc/profile");# remove old setting lines

#`echo 'export PATH=$prefixPath/bin:\$PATH' >> /etc/profile`;
#`echo 'export LD_LIBRARY_PATH=$prefixPath/lib:\$LD_LIBRARY_PATH' >> /etc/profile`;
#print "**** source /etc/profile is required!!!!\n";
#source("/etc/profile");
