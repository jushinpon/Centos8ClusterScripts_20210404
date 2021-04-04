#Perl script to Downlaod and install MPICH developed by Prof. Shin-Pon Ju
#1. You need go to https://www.mpich.org/downloads/ to check the latest mpich version and set the downloading url
#2. compiling procedure
#a. make a directory to download the tar.gz file 
#b.  this file (wget -O mpich XXX)
#c. unziptar xvzf
#d. configure, make, make install
sub path_setting{
	$attached_path = shift;	
	$path = $ENV{'PATH'};
	$ENV{'PATH'} = "$attached_path:$path";
}
	
sub ld_setting {
    $attached_ld = shift;
	$ld_library_path = $ENV{'LD_LIBRARY_PATH'};	
	$ENV{'LD_LIBRARY_PATH'} = "$attached_ld:$ld_library_path";		
}
#$thread4make = 1; # the thread number used for make !!!!!!!	
#$mattached_path = "/opt/mpich-3.3.2/mpich_install/bin";#attached path in main script
#path_setting($mattached_path);
#$mattached_ld = "/opt/mpich-3.3.2/mpich_install/lib";#attached ld path in main script
#ld_setting($mattached_ld);
#$nnp_ld="/home/jsp/n2p2-master/lib";
#ld_setting($mattached_ld);

use Cwd; #Find Current Path
#use FindBin; #Find Path
use File::Copy; # Copy File
 
open Check, ">00QEInstall_Status.txt";
print Check "===========Process status (0 is ok): sysytem call purpose============\n";

$currentVer = "q-e-qe-6.4.1";#***** the latest version of this package
$URL = "https://github.com/QEF/q-e.git";#url to download
$Dir4download = "qe_download"; #the directory we download Mpich

$current_Path = getcwd; #get perl code path

####### in the directory of $MPI_download
system ("rm -rf $Dir4download");# remove the older directory first
system("mkdir $Dir4download");# make a directory in current path

chdir("$current_Path/$Dir4download");# cd to this dir for downloading the packages
#get the latest package in the directory and save it as the filename you want
$Ch = system("git clone $URL");  
print Check "$Ch:wget -O or git clone qe $URL\n";

#$tar_path = getcwd;# get the current path and then unzip the mpich from wget -O
#
#if(! (-e "$tar_path/qe")){die "No $currentVer downloaded";}# if no mpich file
#
## tar -xvzf XXX(package name), and then cd this new folder	
#$Ch = system("tar -xvzf qe"); #$Ch =  Check
#print Check "$Ch: tar -xvzf qe\n";	
#if($Ch != 0){die "tar process failed!\n";}
#./configure --prefix=/home/<USERNAME>/mpich-install
chdir("$current_Path/$Dir4download/q-e");#$currentVer is the directory name after tar
#$Ch = system("./configure CC=gcc CXX=g++ FC=gfortran --prefix=$Current_Path/$get_MPI_Folder/mpich-install"); #./configure
system ("rm -rf $current_Path/$Dir4download/q-e/qe_install");# remove the older directory first
$Ch = system("./configure --prefix=$current_Path/$Dir4download/q-e/qe_install --enable-parallel"); #./configure
print Check "$Ch: configure qe\n";	
if($Ch != 0){die "config process failed!\n";}
#after the configure process is done, type "make" and then "make install"
$Ch = system("make all"); 
print Check "$Ch: make qe\n";
if($Ch != 0){die "make process failed!\n";}

$Ch = system("make install");
print Check "$Ch: make install qe\n";
if($Ch != 0){die "make process failed!\n";}

#if(-d /opt/lammps ){
system ("cp -R $current_Path/$Dir4download/q-e/qe_install /opt/");
#}

print Check "ALL DONE!\n";
close(check);	
