#Perl script to Downlaod and install memtester (developed by Prof. Shin-Pon Ju (2022/Oct/31))
# You need to be root to use this script
#1. You need go to https://pyropus.ca./software/memtester/ to check the latest lammps version and set the downloading url
#2. compiling procedure
#a. make a directory to download the tar.gz file 
#b. get the source zip file and rename it as lammps file (wget -O lammps XXX)
#c. unziptar -xvzf
#d.do the necessary things

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

my $URL = "wget http://pyropus.ca/software/memtester/old-versions/memtester-4.5.1.tar.gz";#url to download
my $folder = "memtester-4.5.1";
#my $URL = "https://lammps.sandia.gov/tars/lammps.tar.gz";#url to download
my $Dir4download = "$packageDir/memtester"; #the directory we download Mpich
my $currentPath = getcwd(); #get perl code path

####### in the directory of $lammps_download
if($wgetORgit eq "yes"){
	system ("rm -rf $Dir4download");# remove the older directory first
	system("mkdir -p $Dir4download");# make a directory in current path
	
	chdir("$Dir4download");# cd to this dir for downloading the packages
	#system("git clone $URL lammps");
	system("wget $URL");
	system("tar xvzf memtester*");
}

`sed -i 's:^INSTALLPATH.*:INSTALLPATH = /opt/memtest:' $Dir4download/$folder/Makefile`;

system("rm -rf /opt/memtest");
system("mkdir -p /opt/memtest");

chdir("$Dir4download/$folder");# cd to this dir for downloading the packages
system("chmod 755 extra-libs.sh");
system("make clean");
system("make -j $thread4make");
system("make install");
system("chmod -R 755 /opt/memtest");
print "*******memtester installation done!\n";
