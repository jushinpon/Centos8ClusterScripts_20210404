#Perl script to Downlaod and install MPICH developed by Prof. Shin-Pon Ju
#1. You need go to https://www.mpich.org/downloads/ to check the latest mpich version and set the downloading url
#2. compiling procedure
#a. make a directory to download the tar.gz file 
#b.  this file (wget -O mpich XXX)
#c. unziptar xvzf
#d. configure, make, make install
#e. --with-slurm=[PATH]  --with-pmix=[PATH] 

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
#path_setting($mattached_path);
my $mattached_ld = "/usr/local/lib";#attached ld path in main script
ld_setting($mattached_ld);

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
my $thread4make = `lscpu|grep "^CPU(s):" | sed 's/^CPU(s): *//g'`;
chomp $thread4make;
print "Total threads can be used for make: $thread4make\n";
#https://www.mpich.org/static/downloads/4.0.3/mpich-4.0.3.tar.gz 2023/01/27
#my $currentVer = "mpich-3.4.2";#***** the latest version of this package
my $currentVer = "mpich-4.0.3";#***** the latest version of this package
my $prefixPath = "/opt/$currentVer";
system ("rm -rf /opt/$currentVer");# remove the older directory first
#my $URL = "https://www.mpich.org/static/downloads/3.4.2/mpich-3.4.2.tar.gz";
my $URL = "https://www.mpich.org/static/downloads/4.0.3/mpich-4.0.3.tar.gz";
my $Dir4download = "$packageDir/mpich_download"; #the directory we download MPICH

###
system ("rm -rf $Dir4download");# remove the older directory first
system("mkdir $Dir4download");# make a directory in current path

chdir("$Dir4download");# cd to this dir for downloading the packages
#get the latest package in the directory and save it as the filename you want
system("wget $URL"); 
if ($?){die "wget -O $currentVer $URL failed\n";}
if(! (-e "$Dir4download/$currentVer.tar.gz")){die "No $currentVer downloaded";}# if no mpich file

## tar -xvzf XXX(package name), and then cd this new folder	
system("rm -rf  $currentVer");
system("tar -xvzf $currentVer.tar.gz"); #$Ch =  Check
if ($?){die "tar -xvzf mpich failed\n";} 

chdir("$Dir4download/$currentVer");#$currentVer is the directory name after tar
unlink "Makefile";
sleep(1);
#--enable-fast=all,O3 --with-slurm-include=/usr/local/include/slurmCPPFLAGS=-I/home/packages/mpich_download/mpich-3.3.2/src/pmi/pmi2/include
system("./configure --prefix=$prefixPath --enable-fast=all,O3");# --with-slurm=[/usr/local] VERBOSE=1 |tee 00mpich_configure.txt"); #./configure
if($?){die "config $currentVer failed!\nReason $?:$!\n";}

##after the configure process is done, type "make" and then "make install"
system("make clean"); 
sleep(1);

system("make -j $thread4make VERBOSE=1 |tee 00mpich_make.txt"); 
if($?){die "make $currentVer process failed!\n Reason $?:$!\n";}

system("make install VERBOSE=1 |tee 00mpich_makeInstall.txt");
if($?){die "make install $currentVer failed!\nReason $?:$!\n";}

system("chmod -R 755 $packageDir");# set the permission for all users

#system("perl -p -i.bak -e 's/.*mpich-.+\n//g;' /etc/profile");# remove old setting lines
#`echo 'export PATH=$prefixPath/bin:\$PATH' >> /etc/profile`;
#`echo 'export LD_LIBRARY_PATH=$prefixPath/lib:\$LD_LIBRARY_PATH' >> /etc/profile`;
