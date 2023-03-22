=Developed by Prof. Shin-Pon Ju at NSYSU Oct.09 2020

1. Perl script to compile and install QE with thermo_pw. You need to check the version of QE for the compatibility to 
thermo_pw version.(https://dalcorso.github.io/thermo_pw/)

2. Download page: https://dalcorso.github.io/thermo_pw/
3. QE : https://github.com/QEF/q-e/releases

4. this installation: thermo_pw.1.3.0.tar.gz compatible with QE-6.5.
**5. check sssp folder next time 
https://www.materialscloud.org/discover/sssp/table/efficiency
5.QE performance: https://glennklockwood.blogspot.com/2014/02/quantum-espresso-compiling-and-choice.html
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
my $mattached_path = "/opt/mpich-4.0.3/bin";#attached path in main script
path_setting($mattached_path);
#/opt/intel/compilers_and_libraries_2018.0.128/linux/mkl/lib/intel64_lin
#my $mattached_ld = "/opt/slurm_mvapich2-2.3.4/lib:/opt/intel/mkl/lib/intel64";#attached ld path in main script
my $mattached_ld = "/opt/mpich-4.0.3/lib:/opt/intel/mkl/lib/intel64";#attached ld path in main script
ld_setting($mattached_ld);

#!/bin/sh
use warnings;
use strict;
use Cwd; #Find Current Path

my $wgetORgit = "yes";## if you want to download the source, use yes. set no, if you have downloaded the source.

my $packageDir = "/home/packages";
if(!-e $packageDir){# if no /home/packages, make this folder	
	system("mkdir $packageDir");	
}

###install intel MKL
system("yum -y install yum-utils");
system("yum-config-manager --add-repo https://yum.repos.intel.com/mkl/setup/intel-mkl.repo");
if($?){die "add intel repo failed!\n";}
system("rpm --import https://yum.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB");
if($?){die "import intel repo key failed!\n";}
system("yum install -y intel-mkl");

my $prefix = "/opt/QEGCC_MPICH4.0.3_thermoPW";
my $package = "q-e";
my $currentVer = "qe-7.1.tar.gz";#***** the latest version of this package (check the latest one if possible)
my $unzipFolder = "q-e-qe-7.1";#***** the unzipped folder of this package (check the latest one if possible)
my $URL = "https://github.com/QEF/q-e/archive/refs/tags/qe-7.1.tar.gz";#url to download
my $Dir4download = "$packageDir/qe_download"; #the directory we download Mpich

## thermo_pw
my $package1 = "ThermoPW";
my $currentVer1 = "thermo_pw.1.7.1.tar.gz";#***** the latest version of this package (check the latest one if possible)
my $unzipFolder1 = "thermo_pw";#***** the unzipped folder of this package (check the latest one if possible)
my $URL1 = "http://people.sissa.it/~dalcorso/thermo_pw/"."$currentVer1";#url to download
#http://people.sissa.it/~dalcorso/thermo_pw/thermo_pw.1.7.0.tar.gz
my $script_CurrentPath = getcwd(); #get perl code path

#chdir("/opt");# cd to this dir for downloading the packages
#system("rm -rf /opt/QEpot");
#system("tar -xvzf $script_CurrentPath/QEpot.tar.gz");
#if($?){die "tar QEpot.tar.gz failed!!\n";}
#die;

chdir("$script_CurrentPath");# cd to this dir for downloading the packages
if($wgetORgit eq "yes"){
	system("rm -rf $Dir4download");# remove the older directory first
	system("mkdir $Dir4download");# make a directory in current path

##download qe and thermo_pw
	chdir("$Dir4download");# cd to this dir for downloading the packages
##get the latest package in the directory and save it as the filename you want
	system("wget $URL"); # download qe
	if($?){die "wget $URL failed!!\n";} 
	system("wget $URL1"); # download thermo_pw
	if($?){die "wget $URL1 failed!!\n";}
	chdir("$script_CurrentPath");

} 

chdir("$Dir4download");# cd to this dir for downloading the packages

system("rm -rf $unzipFolder");
system("tar xvzf $currentVer");#unzip qe
if($?){die "tar xvzf $currentVer failed!!\n";} 

system("rm -rf $unzipFolder1");
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

my $prefix4QE = "--prefix=$prefix";
system("rm -rf $prefix");

#system("./configure $prefix F90=ifort F77=mpiifort MPIF90=mpiifort CC=mpiicc $BLAS_LIBS $LAPACK_LIBS $SCALAPACK_LIBS $FFT_LIBS $FFLAGS $MPI_LIBS --enable-parallel");
# find all threads to make this package
my $thread4make = `lscpu|grep "^CPU(s):" | sed 's/^CPU(s): *//g'`;
print "Total threads can be used for make: $thread4make\n";

my $BLAS_LIBS="BLAS_LIBS=\"-L/opt/intel/mkl/lib/intel64 -lmkl_gf_lp64 -lmkl_sequential -lmkl_core\"";
#my $LAPACK_LIBS="LAPACK_LIBS=\"-L\$\{MKLROOT\}/lib/intel64 -lmkl_scalapack_lp64 -lmkl_gf_lp64 -lmkl_sequential -lmkl_core -lmkl_blacs_openmpi_lp64 -lpthread -lm -ldl\"";-lmkl_blacs_openmpi_lp64
my $SCALAPACK_LIBS="SCALAPACK_LIBS=\"-L/opt/intel/mkl/lib/intel64 -L/opt/slurm_mvapich2-2.3.4/lib -lmkl_scalapack_lp64 -lmkl_gf_lp64 -lmkl_sequential -lmkl_core  -lpthread -lm -ldl\"";
my $FFT_LIBS="FFT_LIBS=\"-L/opt/intel/mkl/lib/intel64 -L/opt/slurm_mvapich2-2.3.4/lib -lmkl_scalapack_lp64 -lmkl_gf_lp64 -lmkl_blacs_openmpi_lp64 -lmkl_sequential -lmkl_core\"";
my $FFLAGS="FFLAGS=\"-O3 \"";
my $MPI_LIBS ="MPI_LIBS=\"-L/opt/slurm_mvapich2-2.3.4/lib -lmpi\"";#### need to use your own path for impi
my $LIBDIRS="LIBDIRS=\"/opt/slurm_mvapich2-2.3.4/lib\"";
#$SCALAPACK_LIBS -with-scalapack=yes $FFT_LIBS $MPI_LIBS $LIBDIRS $BLAS_LIBS $SCALAPACK_LIBS
#system("./configure --enable-parallel $prefix");-with-scalapack=intel
system("./configure --enable-parallel  $FFLAGS $prefix4QE");
if($?){die "**QE configure fails!\nReason:$?\n";}
#after the configure process is done, type "make" and then "make install"
system("make clean"); 
if($?){die "**make QE clean fails";}

chdir("$Dir4download/$unzipFolder/thermo_pw");# cd to this dir for downloading the packages
system("make join_qe");
if($?){die "make join_qe in thermo_pw directory failed!\nReason:$?\n";}

chdir("$Dir4download/$unzipFolder");# cd to this dir for downloading the packages

system("make thermo_pw -j $thread4make"); 
#system("make pw -j $thread4make"); 
#system("make all -j $thread4make"); #cp.x
#if($?){die "make qe failed!\nReason:$?\n";}
sleep(1);
system("make install"); 
#if($?){die "make install failed!\n";}
print "QE with thermo_pw has been successfully installed!!\n";

#if(!-e "/opt/QEsssp"){# if no /home/packages, make this folder	
#	system("mkdir /opt/QEsssp");	
#	system("mkdir /opt/QEsssp/Efficiency");	
#	system("mkdir /opt/QEsssp/Precision");	
#}

print "\n*****You need to download SSSP potential for QE!!\n";
