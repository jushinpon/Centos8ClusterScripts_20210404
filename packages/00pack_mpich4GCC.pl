#Perl script to Downlaod and install MPICH developed by Prof. Shin-Pon Ju
#1. You need go to https://www.mpich.org/downloads/ to check the latest mpich version and set the downloading url
#2. compiling procedure
#a. make a directory to download the tar.gz file 
#b.  this file (wget -O mpich XXX)
#c. unziptar xvzf
#d. configure, make, make install
#e. --with-slurm=[PATH]  --with-pmix=[PATH] 
use warnings;
use strict;
use Env::Modify qw(:sh source);
use Cwd; #Find Current Path
use File::Copy; # Copy File

my $packageDir = "/home/packages";
if(!-e $packageDir){# if no /home/packages, make this folder	
	system("mkdir $packageDir");	
}

my $current_path = getcwd();# get the current path dir

# find all threads to make this package
my $socketNo = `lscpu|grep "^Socket(s):" | sed 's/^Socket(s): *//g'`; 
chomp $socketNo;

my $corePsocket = `lscpu|grep "^Core(s) per socket:" | sed 's/^Core(s) per socket: *//g'`; 
chomp $corePsocket;

my $threadPcore = `lscpu|grep "^Thread(s) per core:" | sed 's/^Thread(s) per core: *//g'`;
chomp $threadPcore;
print "***socketNo, corePsocket, threadPcore: $socketNo, $corePsocket, $threadPcore\n";
my $thread4make = $socketNo * $corePsocket * $threadPcore;
print "Total threads can be used for make: $thread4make\n";


#my $outputDir = "$packageDir/mpi_output"; # for output files
#system ("rm -rf $outputDir");# remove the older directory first
#mkdir("$outputDir"); 
#open my $Check, "> ./$outputDir/mpichInstall_Status.txt";
#print $Check "===========Process status (0 is ok): sysytem call return============\n";

my $currentVer = "mpich-3.3.2";#***** the latest version of this package
my $prefixPath = "/opt/$currentVer";
system ("rm -rf /opt/$currentVer");# remove the older directory first
my $URL = "http://www.mpich.org/static/downloads/3.3.2/mpich-3.3.2.tar.gz";
my $Dir4download = "$packageDir/mpich_download"; #the directory we download MPICH

###
#system ("rm -rf $Dir4download");# remove the older directory first
#system("mkdir $Dir4download");# make a directory in current path

chdir("$Dir4download");# cd to this dir for downloading the packages
#get the latest package in the directory and save it as the filename you want
#system("wget -O $currentVer $URL"); 
#if ($?){die "wget -O $currentVer $URL failed\n";}
#if(! (-e "$Dir4download/$currentVer")){die "No $currentVer downloaded";}# if no mpich file

# tar -xvzf XXX(package name), and then cd this new folder	
#system("tar -xvzf $currentVer"); #$Ch =  Check
#if ($?){die "tar -xvzf mpich failed\n";} 

chdir("$Dir4download/$currentVer");#$currentVer is the directory name after tar
#$Ch = system("./configure CC=gcc CXX=g++ FC=gfortran --prefix=$Current_Path/$get_MPI_Folder/mpich-install --with-device=ch4:ofi"); #./configure
#system("./configure --prefix=$prefixPath"); #./configure
#./configure --prefix=$prefixPath --with-slurm=<PATH> --with-pmi=pmi2 --with-pmix=[/opt/pmix/install/2.1]
system("./configure --prefix=$prefixPath  --enable-fast=all,O3 --with-pmi=slurm --with-pm=no --with-slurm=[/usr/local] VERBOSE=1 |tee 00mpich_configure.txt"); #./configure
if($?){die "config $currentVer failed!\nReason $?:$!\n";}

#after the configure process is done, type "make" and then "make install"
system("make clean"); 
sleep(1);

system("make -j $thread4make VERBOSE=1 |tee 00mpich_make.txt"); 
if($?){die "make $currentVer process failed!\n Reason $?:$!\n";}

system("make install VERBOSE=1 |tee 00mpich_makeInstall.txt");
if($?){die "make install $currentVer failed!\nReason $?:$!\n";}

system("chmod -R 755 $packageDir");# set the permission for all users

system("perl -p -i.bak -e 's/.*mpich-.+\n//g;' /etc/profile");# remove old setting lines

`echo 'export PATH=$prefixPath/bin:\$PATH' >> /etc/profile`;
`echo 'export LD_LIBRARY_PATH=$prefixPath/lib:\$LD_LIBRARY_PATH' >> /etc/profile`;
print "**** source /etc/profile is required!!!!\n";
source("/etc/profile");
#system ("rm -rf /opt/$currentVer");
#system("mkdir /opt/$currentVer");
#system ("cp -r $current_path/$Dir4download/$currentVer/mpich_install /opt/$currentVer");
#if($? != 0){die "cp -r $current_path/$Dir4download/$currentVer/mpich_install /opt/$currentVer failed!\n";}
