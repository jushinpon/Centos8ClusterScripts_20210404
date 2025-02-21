=Developed by Prof. Shin-Pon Ju at NSYSU Oct.09 2020
conda deactivate first
source /opt/intel/oneapi/setvars.sh
sudo dnf install -y openmpi openmpi-devel

module load mpi/openmpi-x86_64
need the following:
dnf install -y environment-modules
source /etc/profile.d/modules.sh

1. Perl script to compile and install QE with thermo_pw. You need to check the version of QE for the compatibility to 
thermo_pw version.(https://dalcorso.github.io/thermo_pw/)

2. Download page: https://dalcorso.github.io/thermo_pw/
3. QE : https://github.com/QEF/q-e/releases

4. this installation: thermo_pw.1.3.0.tar.gz compatible with QE-6.5.
**5. check sssp folder next time 
https://www.materialscloud.org/discover/sssp/table/efficiency
5.QE performance: https://glennklockwood.blogspot.com/2014/02/quantum-espresso-compiling-and-choice.html
source /opt/intel/oneapi/setvars.sh

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
#my $mattached_path = "/opt/mpich-3.3.2/bin";#attached path in main script
my $mattached_path = "/opt/openmpi-5.0.6/bin";#attached path in main script
path_setting($mattached_path);
#/opt/intel/compilers_and_libraries_2018.0.128/linux/mkl/lib/intel64_lin
#my $mattached_ld = "/opt/slurm_mvapich2-2.3.4/lib:/opt/intel/mkl/lib/intel64";#attached ld path in main script
#my $mattached_ld = "/opt/mpich-3.3.2/lib:/opt/intel/mkl/lib/intel64";#attached ld path in main script
my $mattached_ld = "/opt/openmpi-5.0.6/lib:/opt/intel/oneapi/mkl/latest/lib";#attached ld path in main script
ld_setting($mattached_ld);

#!/bin/sh
use warnings;
use strict;
use Cwd; #Find Current Path

my $wgetORgit = "no";## if you want to download the source, use yes. set no, if you have downloaded the source.

my $packageDir = "/home/packages";
if(!-e $packageDir){# if no /home/packages, make this folder	
	system("mkdir $packageDir");	
}

###install intel MKL
#system("yum -y install yum-utils");
#system("yum-config-manager --add-repo https://yum.repos.intel.com/mkl/setup/intel-mkl.repo");
#if($?){die "add intel repo failed!\n";}
#system("rpm --import https://yum.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB");
#if($?){die "import intel repo key failed!\n";}
#system("yum install -y intel-mkl");

#my $prefix = "/opt/QEGCC_MPICH3.3.2_thermoPW";
my $prefix = "/opt/thermoPW-7-2_avx2openmpi5";
#my $prefix = "/opt/thermoPW-7-2_intel";
#my $prefix = "/opt/QEGCC_MPICH4.0.3_thermoPW";
my $package = "q-e";
#my $currentVer = "qe-6.5.tar.gz";#***** the latest version of this package (check the latest one if possible)
my $currentVer = "qe-7.2.tar.gz";#***** the latest version of this package (check the latest one if possible)
#my $unzipFolder = "q-e-qe-6.5";#***** the unzipped folder of this package (check the latest one if possible)
my $unzipFolder = "q-e-qe-7.2";#***** the unzipped folder of this package (check the latest one if possible)
#my $URL = "https://github.com/QEF/q-e/archive/qe-6.5.tar.gz";#url to download
my $URL = "https://github.com/QEF/q-e/archive/refs/tags/qe-7.2.tar.gz";#url to download
my $Dir4download = "$packageDir/qe_download"; #the directory we download Mpich

## thermo_pw
my $package1 = "ThermoPW";
my $currentVer1 = "thermo_pw.1.8.1.tar.gz";#***** the latest version of this package (check the latest one if possible)
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

chdir("$Dir4download/$unzipFolder/thermo_pw");# cd to this dir for downloading the packages
system("make leave_qe");
system("make join_qe");
if($?){die "make join_qe in thermo_pw directory failed!\nReason:$?\n";}

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
#my $FFLAGS="FFLAGS=\"-O3 \"";#ok
#my $FFLAGS="FFLAGS=\"-O3 -xHost -march=native -fopenmp\"";#ok
#my $FFLAGS="FFLAGS=\"-O3 -fopenmp\"";#for cluster works -xCORE-AVX2 -no-prec-div
# Set up compilation options with AVX2
my $FFLAGS = "FFLAGS=\"-O3 -mavx2 -mfma -fopenmp -funroll-loops\"";
my $CFLAGS = "CFLAGS=\"-O3 -mavx2 -mfma -fopenmp -funroll-loops\"";

#my $FFLAGS="FFLAGS=\"-O3 -xHost -no-prec-div -fopenmp\"";#for cluster works
my $MPI_LIBS ="MPI_LIBS=\"-L/opt/slurm_mvapich2-2.3.4/lib -lmpi\"";#### need to use your own path for impi
my $LIBDIRS="LIBDIRS=\"/opt/slurm_mvapich2-2.3.4/lib\"";
#$SCALAPACK_LIBS -with-scalapack=yes $FFT_LIBS $MPI_LIBS $LIBDIRS $BLAS_LIBS $SCALAPACK_LIBS
#system("./configure --enable-parallel $prefix");-with-scalapack=intel
#system("./configure  $FFLAGS $prefix4QE");
my $fftw_link = '-L${MKLROOT}/lib/intel64 -lmkl';
#MKL 2024
my $link = '-L${MKLROOT}/lib -lmkl_scalapack_lp64 -lmkl_intel_lp64 -lmkl_intel_thread -lmkl_core -lmkl_blacs_intelmpi_lp64 -liomp5 -lpthread -lm -ldl';
#my $link = ' -L${MKLROOT}/lib -lmkl_intel_lp64 -lmkl_intel_thread -lmkl_core -lmkl_blacs_intelmpi_lp64 -liomp5 -lpthread -lm -ldl';

#my $link = '-L${MKLROOT}/lib/intel64 -lmkl_scalapack_lp64 -lmkl_intel_lp64 -lmkl_intel_thread -lmkl_core -lmkl_blacs_intelmpi_lp64 -liomp5 -lpthread -lm -ldl';
#sequential
#my $link = '-L${MKLROOT}/lib/intel64 -lmkl_scalapack_lp64 -lmkl_intel_lp64 -lmkl_sequential -lmkl_core -lmkl_blacs_intelmpi_lp64 -lpthread -lm -ldl';
#--with-scalapack=intel --enable-openmp CC=icc CXX=icpc --enable-openmp --enable-static $FFLAGS
#my $QE_inst = "./configure --enable-parallel --enable-openmp  --enable-shared  ";#.ok --with-scalapack=intel
###
#my $QE_inst = "./configure --enable-parallel --enable-openmp --enable-shared --with-scalapack=intel ".
#"CC=mpicc FC=mpif90 F77=mpif90 MPIF90=mpif90 $FFLAGS $prefix4QE ";#ok --enable-share$FFLAGSd--enable-parallel --enable-openmp --with-scalapack=intel

my $QE_inst = "./configure --enable-parallel --enable-openmp ".
" $FFLAGS $CFLAGS $prefix4QE ".
"CC=mpicc FC=mpif90 F77=mpif90 MPIF90=mpif90 $FFLAGS $CFLAGS $prefix4QE ";#.
#" --with-blas=\"-L\${MKLROOT}/lib/intel64 -lmkl_intel_lp64 -lmkl_sequential -lmkl_core -lpthread -lm -ldl\" ".
#"--with-lapack=\"-L\${MKLROOT}/lib/intel64 -lmkl_intel_lp64 -lmkl_sequential -lmkl_core -lpthread -lm -ldl\"";#ok --enable-share$FFLAGSd--enable-parallel --enable-openmp 

#my $QE_inst = "./configure --enable-parallel --enable-openmp --with-scalapack=intel $link $FFLAGS --enable-shared $prefix4QE ";#not ok
#"FFLAGS=\"-O3 -assume byterecl -g -traceback -qopenmp\" ".
#"LAPACK_LIBS=\"$link\" ".
#"BLAS_LIBS=\"$link\" ".
#"SCALAPACK_LIBS=\"$link\" ".
##"CFLAGS=\"-O3 -qopenmp\" ".
#"LDFLAGS=\"-qopenmp\" ";#.
##"FFT_LIBS=\"$fftw_link\" ".
#"LAPACK=\"liblapack\"";
print "\$QE_inst: $QE_inst";
system("make veryclean;$QE_inst");
die;
if($?){die "**QE configure fails!\nReason:$?\n";}
#after the configure process is done, type "make" and then "make install"
system("make clean"); 
if($?){die "**make QE clean fails";}
print "$thread4make";
#system("make pwall");
system("make pwall -j\$(nproc)") == 0 or die "Make failed!";
sleep(1);

system("ls bin");
 
#system("make pw -j $thread4make"); 
#system("make all -j $thread4make"); #cp.x
#if($?){die "make qe failed!\nReason:$?\n";}
system("make install"); 
#if($?){die "make install failed!\n";}
print "QE with thermo_pw has been successfully installed!!\n";
print "\n\nCheck thermo_pw.x in $prefix/bin!! \n\n";
system("ls $prefix/bin"); 
#if(!-e "/opt/QEsssp"){# if no /home/packages, make this folder	
#	system("mkdir /opt/QEsssp");	
#	system("mkdir /opt/QEsssp/Efficiency");	
#	system("mkdir /opt/QEsssp/Precision");	
#}

print "\n*****You need to download SSSP potential for QE!!\n";
