#Perl script to Downlaod and install UCX (Jan 15 2021 by Prof. Shin-Pon Ju)
#1. https://github.com/openucx/ucx

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

my $currentVer = "UCX-1.8";#***** the latest version of this package
my $prefixPath = "/opt/$currentVer";#you may use your own
system ("rm -rf $prefixPath");# remove the older directory first
my $URL = "https://github.com/openucx/ucx";
my $Dir4download = "$packageDir/$currentVer"."_download"; #the directory we download MPICH

###
system ("rm -rf $Dir4download");# remove the older directory first
system("mkdir $Dir4download");# make a directory in current path

chdir("$Dir4download");# cd to this dir for downloading the packages
#get the latest package in the directory and save it as the filename you want
system("git clone $URL"); 
if ($?){die "git clone $URL failed\n";}
chdir ($current_path);
## tar -xvzf XXX(package name), and then cd this new folder	
#system("rm -rf  $currentVer");
#system("tar -xvzf $currentVer.tar.gz"); #$Ch =  Check
#if ($?){die "tar -xvzf mpich failed\n";} 

chdir("$Dir4download/ucx");#$currentVer is the directory name after tar
system("git checkout v1.8.x");
system("git pull");
system("git status");
sleep(3);
unlink "Makefile";
sleep(1);
#--enable-fast=all,O3 --with-slurm-include=/usr/local/include/slurmCPPFLAGS=-I/home/packages/mpich_download/mpich-3.3.2/src/pmi/pmi2/include
system("./autogen.sh");
system("./contrib/configure-devel --prefix=$prefixPath --enable-optimizations --disable-logging --disable-debug --disable-assertions --disable-params-check");# --with-slurm=[/usr/local] VERBOSE=1 |tee 00mpich_configure.txt"); #./configure
if($?){die "config $currentVer failed!\nReason $?:$!\n";}

##after the configure process is done, type "make" and then "make install"
system("make clean"); 
sleep(1);

system("make -j $thread4make |tee 00ucx_make.txt"); 
if($?){die "make $currentVer process failed!\n Reason $?:$!\n";}

system("make install |tee 00ucx_makeInstall.txt");
if($?){die "make install $currentVer failed!\nReason $?:$!\n";}
chdir ($current_path);

system("chmod -R 755 $packageDir");# set the permission for all users

#system("perl -p -i.bak -e 's/.*mpich-.+\n//g;' /etc/profile");# remove old setting lines
#`echo 'export PATH=$prefixPath/bin:\$PATH' >> /etc/profile`;
#`echo 'export LD_LIBRARY_PATH=$prefixPath/lib:\$LD_LIBRARY_PATH' >> /etc/profile`;
