#Perl script to Downlaod and install MPICH by using different GCC versions (developed by Prof. Shin-Pon Ju)
# You need to check what GCC versions have been installed. (/opt/rh/) 

#1. You need go to https://www.mpich.org/downloads/ to check the latest mpich version and set the downloading url
#2. compiling procedure
#a. make a directory to download the tar.gz file 
#b.  this file (wget -O mpich XXX)
#c. unziptar xvzf
#d. configure, make, make install
use warnings;
use strict;
#use Env::Modify qw(:sh source);
use Cwd; #Find Current Path
use File::Copy; # Copy File
my @GCC_Version = (7,8,9); # GCC versions have been installed in "/opt/rh/" 

my $current_path = getcwd;# get the current path dir
my $outputDir = "mpi_output"; # for output files
system ("rm -rf $outputDir");# remove the older directory first
mkdir("$outputDir"); 
open my $Check, "> ./$outputDir/mpichInstall_Status.txt";
print $Check "===========Process status (0 is ok): sysytem call return============\n";

my $currentVer = "mpich-3.3.2";#***** the latest version of this package
my $URL = "http://www.mpich.org/static/downloads/3.3.2/mpich-3.3.2.tar.gz";#url to download
my $Dir4download = "mpich_download"; #the directory we download Mpich
#my $script_CurrentPath = $FindBin::Bin; #get perl code path

system ("rm -rf $Dir4download");# remove the older directory first
system("mkdir $Dir4download");# make a directory in current path

chdir("$current_path/$Dir4download");# cd to this dir for downloading the packages
#get the latest package in the directory and save it as the filename you want
system("wget -O mpich $URL"); 
if ($? != 0){die "wget -O mpich $URL failed\n";} 
print $Check "$?:wget -O mpich $URL\n";

if(! (-e "$current_path/$Dir4download/mpich")){die "No $currentVer downloaded";}# if no mpich file

# tar -xvzf XXX(package name), and then cd this new folder	
system("tar -xvzf mpich"); #$Ch =  Check
if ($? != 0){die "tar -xvzf mpich failed\n";} 
print $Check "$?: tar -xvzf mpich\n";	
#./configure --prefix=/home/<USERNAME>/mpich-install
chdir("$current_path/$Dir4download/$currentVer");#$currentVer is the directory name after tar
#$Ch = system("./configure CC=gcc CXX=g++ FC=gfortran --prefix=$Current_Path/$get_MPI_Folder/mpich-install"); #./configure
for my $GV (@GCC_Version){
    chomp $GV;
    source("/opt/rh/devtoolset-$GV/enable"); # enable GCC of this version for current shell and all subshell
    system ("rm -rf $current_path/$Dir4download/$currentVer/$currentVer"."_GCC$GV");# remove the older directory first
    my $GCCcheck = `gcc -v`;

    print $Check "\n\n****GCC version check: $GCCcheck\n\n";
    
    system("./configure --prefix=$current_path/$Dir4download/$currentVer/$currentVer"."_GCC$GV"); #./configure
    if($? != 0){die "config $currentVer failed!\n";}
    print $Check "$?: configure $currentVer\n";	
    #after the configure process is done, type "make" and then "make install"
    system("make clean"); 
    sleep(1);
    system("make"); 
    if($? != 0){die "make $currentVer process failed!\n";}
    print $Check "$?: make $currentVer\n";

    system("make install");
    if($? != 0){die "make install $currentVer failed!\n";}
    print $Check "$?: make install $currentVer\n";

    print $Check "ALL DONE!\n";
    
    system ("rm -rf /opt/$currentVer"."_GCC$GV");
    system("mkdir /opt/$currentVer"."_GCC$GV");
    system ("cp -r $current_path/$Dir4download/$currentVer/$currentVer"."_GCC$GV /opt/");
    if($? != 0){die "cp -r $current_path/$Dir4download/$currentVer/$currentVer"."_GCC$GV /opt/ failed!\n";}

}
close($Check);
#setting path and ld_library_path

system("perl -p -i.bak -e 's/.*mpich-.+\n//g;' /etc/profile");# remove old setting lines

#`echo 'export PATH=/opt/$currentVer/mpich_install/bin:\$PATH' >> /etc/profile`;
#`echo 'export LD_LIBRARY_PATH=/opt/$currentVer/mpich_install/lib:\$LD_LIBRARY_PATH' >> /etc/profile`;
#print "You need to logout for new path setting\n";
