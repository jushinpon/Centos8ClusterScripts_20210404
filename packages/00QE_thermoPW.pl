=Developed by Prof. Shin-Pon Ju at NSYSU Oct.09 2020

1. Perl script to compile and install QE with thermo_pw. You need to check the version of QE for the compatibility to 
thermo_pw version.(https://dalcorso.github.io/thermo_pw/)

2. Download page: https://dalcorso.github.io/thermo_pw/
3. QE : https://github.com/QEF/q-e/releases

4. this installation: thermo_pw.1.3.0.tar.gz compatible with QE-6.5.
**5. check sssp folder next time 
https://www.materialscloud.org/discover/sssp/table/efficiency
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
my $mattached_path = "/opt/mpich-3.3.2/bin";#attached path in main script
path_setting($mattached_path);
my $mattached_ld = "/opt/mpich-3.3.2/lib";#attached ld path in main script
ld_setting($mattached_ld);

#!/bin/sh
use warnings;
use strict;
use Cwd; #Find Current Path

my $packageDir = "/home/packages";
if(!-e $packageDir){# if no /home/packages, make this folder	
	system("mkdir $packageDir");	
}

my $package = "q-e";
my $currentVer = "qe-6.5.tar.gz";#***** the latest version of this package (check the latest one if possible)
my $unzipFolder = "q-e-qe-6.5";#***** the unzipped folder of this package (check the latest one if possible)
my $URL = "https://github.com/QEF/q-e/archive/qe-6.5.tar.gz";#url to download
my $Dir4download = "$packageDir/qe_download"; #the directory we download Mpich

## thermo_pw
my $package1 = "ThermoPW";
my $currentVer1 = "thermo_pw.1.3.0.tar.gz";#***** the latest version of this package (check the latest one if possible)
my $unzipFolder1 = "thermo_pw";#***** the unzipped folder of this package (check the latest one if possible)
my $URL1 = "http://people.sissa.it/~dalcorso/thermo_pw/"."$currentVer1";#url to download

my $script_CurrentPath = getcwd; #get perl code path
system("rm -rf $Dir4download");# remove the older directory first
system("mkdir $Dir4download");# make a directory in current path

##download qe
chdir("$Dir4download");# cd to this dir for downloading the packages
##get the latest package in the directory and save it as the filename you want
system("wget $URL"); # download qe
if($?){die "wget $URL failed!!\n";} 
system("wget $URL1"); # download thermo_pw
if($?){die "wget $URL1 failed!!\n";} 

system("tar xvzf $currentVer");#unzip qe
if($?){die "tar xvzf $currentVer failed!!\n";} 
system("tar xvzf $currentVer1");#unzip thermo_pw
if($?){die "tar xvzf $currentVer1 failed!!\n";} 

if(! -d "$Dir4download/$unzipFolder" ){
	die "No $unzipFolder folder after tar! You need to find the correct folder name\n";
}

if(! -d "$Dir4download/$unzipFolder1" ){
	die "No $unzipFolder1 folder after tar! You need to find the correct folder name\n";
}
#copy required files and make (check "usage" of https://github.com/dalcorso/thermo_pw)
system("rm -rf $Dir4download/$unzipFolder/$unzipFolder1");
system("cp -r $Dir4download/$unzipFolder1 $Dir4download/$unzipFolder/");
if($?){die "copy thermo_pw to qe folder failed!\n";}

chdir("$Dir4download/$unzipFolder");# cd to this dir for downloading the packages
my $date=`date +%Y%m%d`;
my $prefix = "--prefix=/opt/QEGCC";
#system("./configure $prefix F90=ifort F77=mpiifort MPIF90=mpiifort CC=mpiicc $BLAS_LIBS $LAPACK_LIBS $SCALAPACK_LIBS $FFT_LIBS $FFLAGS $MPI_LIBS --enable-parallel");
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
sleep(1);
system("./configure --enable-parallel $prefix");
if($?){die "**QE configure fails!\nReason:$?\n";}
#after the configure process is done, type "make" and then "make install"
system("make clean"); 
if($?){die "**make QE clean fails";}

chdir("$Dir4download/$unzipFolder/$unzipFolder1");# cd to this dir for downloading the packages
system("make join_qe");
if($?){die "make join_qe in thermo_pw directory failed!\nReason:$?\n";}

chdir("$Dir4download/$unzipFolder");# cd to this dir for downloading the packages

system("make pwall -j $thread4make"); 
#if($?){die "make qe failed!\nReason:$?\n";}
sleep(1);
system("make install"); 
#if($?){die "make install failed!\n";}
print "QE with thermo_pw has been successfully installed!!\n";

if(!-e "/opt/QEsssp"){# if no /home/packages, make this folder	
	system("mkdir /opt/QEsssp");	
	system("mkdir /opt/QEsssp/Efficiency");	
	system("mkdir /opt/QEsssp/Precision");	
}

print "\n*****You need to download SSSP potential for QE!!\n";
