=Developed by Prof. Shin-Pon Ju at NSYSU Oct.09 2020

Perl script to compile and install thermo_pw. You need to check the version of QE for the compatibility to 
thermo_pw version.(https://people.sissa.it/~dalcorso/thermo_pw/user_guide/node5.html)
Download page: https://dalcorso.github.io/thermo_pw/
*******IMPORTANT**********

=cut

#!/bin/sh
use warnings;
use strict;

#use Env::Modify qw(:sh source); #you have to install this perl's mod
use Cwd; #Find Current Path
#use FindBin; #Find Path
#use File::Copy; # Copy File
my $package = "ThermoPW";
my $currentVer = "thermo_pw.1.3.2.tar.gz";#***** the latest version of this package (check the latest one if possible)
my $unzipFolder = "thermo_pw.1.3.2";#***** the latest version of this package (check the latest one if possible)

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
#sleep(30);

open my $Check, "> $package"."_InstallStatus.txt";
print $Check "===========Process status (0 is ok): sysytem call purpose============\n";

my $URL = "http://people.sissa.it/~dalcorso/thermo_pw/"."$currentVer";#url to download
my $Dir4download = "thermo_pw"; #the directory we download Mpich

my $script_CurrentPath = getcwd(); #get perl code path
system("rm -rf $Dir4download");# remove the older directory first
system("mkdir $Dir4download");# make a directory in current path

#download thermo_pw
chdir("$script_CurrentPath/$Dir4download");# cd to this dir for downloading the packages
#get the latest package in the directory and save it as the filename you want
##system("git clone $URL");  
system("wget $URL");  
print $Check "$?:wget $currentVer \n";

if ($?){die "wget $currentVer failed\n";} 

# tar -xvzf XXX(package name), and then cd this new folder	
system("tar -xvzf $currentVer"); #$Ch =  Check
if ($?){die "tar -xvzf $currentVer failed\n";} 
print $Check "$?: tar -xvzf $currentVer\n";	
#./configure --prefix=/home/<USERNAME>/mpich-install
#chdir("$current_path/$Dir4download/$currentVer");
#
chdir("$script_CurrentPath/$Dir4download/$unzipFolder");
#my $prefix = "--prefix=/opt/QE_PSXE2020";
my $prefix = "--prefix=/opt/QEGCC";
#system ("rm -rf /opt/QE_PSXE2020");# remove the older directory first
#print "";
#my $BLAS_LIBS="BLAS_LIBS=\"-L\$\{MKLROOT\}/lib/intel64 -lmkl_scalapack_lp64 -lmkl_intel_lp64 -lmkl_sequential -lmkl_core -lmkl_blacs_intelmpi_lp64 -lpthread -lm -ldl\"";
#my $LAPACK_LIBS="LAPACK_LIBS=\"-L\$\{MKLROOT\}/lib/intel64 -lmkl_scalapack_lp64 -lmkl_intel_lp64 -lmkl_sequential -lmkl_core -lmkl_blacs_intelmpi_lp64 -lpthread -lm -ldl\"";
#my $SCALAPACK_LIBS="SCALAPACK_LIBS=\"-L\$\{MKLROOT\}/lib/intel64 -lmkl_scalapack_lp64 -lmkl_intel_lp64 -lmkl_sequential -lmkl_core -lmkl_blacs_intelmpi_lp64 -lpthread -lm -ldl\"";
#my $FFT_LIBS="FFT_LIBS=\"-L\$\{MKLROOT\}/lib/intel64 -lmkl_scalapack_lp64 -lmkl_intel_lp64 -lmkl_sequential -lmkl_core -lmkl_blacs_intelmpi_lp64 -lpthread -lm -ldl\"";
#my $FFLAGS="FFLAGS=\"-O3 -assume byterecl -g -traceback\"";
#my $MPI_LIBS ="MPI_LIBS=\"-L/home/intel_compiler/impi/2019.7.217/intel64/lib -lmpi\"";#### need to use your own path for impi

#system("./configure $prefix F90=ifort F77=mpiifort MPIF90=mpiifort CC=mpiicc $BLAS_LIBS $LAPACK_LIBS $SCALAPACK_LIBS $FFT_LIBS $FFLAGS $MPI_LIBS --enable-parallel");
system("./configure $prefix --enable-parallel");
if($? != 0 ){die "**QE configure fails";}
#after the configure process is done, type "make" and then "make install"
system("make clean"); 
if($? != 0 ){die "**make QE fails";}
system("make pw -j $thread4make"); 
print $Check "$?: make qe\n";
sleep(3);
system("make install"); 
print $Check "ALL DONE!\n";
close($Check);	#
