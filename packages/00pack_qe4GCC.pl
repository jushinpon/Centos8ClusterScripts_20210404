#Perl script to compiler QE using intel compiler and MKL, developed by Prof. Shin-Pon Ju

#*******IMPORTANT**********
#1. You need go to install intel compilers with all required modules. Then append "source <path>/psxevars.sh" into /etc/bashrc
#2. then source /etc/bashrc to activate the intel compiler 
#
#!/bin/sh
use warnings;
use strict;

use Env::Modify qw(:sh source); #you have to install this perl's mod
use Cwd; #Find Current Path
use FindBin; #Find Path
use File::Copy; # Copy File

my $core4make = 8;
open my $Check, ">00qeInstall_Status.txt";
print $Check "===========Process status (0 is ok): sysytem call purpose============\n";

my $URL = "https://github.com/QEF/q-e.git";#url to download
my $Dir4download = "qe_download"; #the directory we download Mpich

my $script_CurrentPath = getcwd; #get perl code path
system("rm -rf $Dir4download");# remove the older directory first
system("mkdir $Dir4download");# make a directory in current path

#download qe
chdir("$script_CurrentPath/$Dir4download");# cd to this dir for downloading the packages
#get the latest package in the directory and save it as the filename you want
system("git clone $URL");  
print $Check "$?:wget -O or git clone qe $URL\n";
#
chdir("$script_CurrentPath/$Dir4download/q-e");
#my $prefix = "--prefix=/opt/QE_PSXE2020";
system ("rm -rf /opt/QEGCC");
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
system("./configure $prefix -enable-parallel");
if($? != 0 ){die "**QE configure fails";}
#after the configure process is done, type "make" and then "make install"
system("make clean"); 
if($? != 0 ){die "**make QE fails";}
system("make pw -j $core4make"); 
print $Check "$?: make qe\n";
sleep(3);
system("make install"); 
print $Check "ALL DONE!\n";
close($Check);	#
