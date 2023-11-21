=Developed by Prof. Shin-Pon Ju at NSYSU SEP.23 2023

1. Perl script to compile and install QE GPU version. 
https://gitlab.com/QEF/q-e.git

2. HPC SDK:
https://developer.nvidia.com/hpc-sdk

https://forums.developer.nvidia.com/t/compiling-quantum-espresso-with-gpu-support/222227
./configure --with-cuda="/central/scratch/(username)/nvidia/hpc_sdk/Linux_x86_64/22.7/cuda" --with-cuda-runtime=11.7 --with-cuda-cc=6.0 --enable-openmp --with-scalapack='intel' --with-cuda-mpi=yes --libdir="/central/scratch/(username)/nvidia/hpc_sdk/Linux_x86_64/22.7/math_libs"

https://docs.nvidia.com/hpc-sdk/hpc-sdk-release-notes/index.html

module use /opt/nvidia/hpc_sdk/modulefiles/nvhpc/
module load /opt/nvidia/hpc_sdk/modulefiles/nvhpc/23.7

$ sudo dnf config-manager --add-repo https://developer.download.nvidia.com/hpc-sdk/rhel/nvhpc.repo
$ sudo dnf install -y nvhpc-cuda-multi-23.7
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
use Cwd; #Find Current Path
#my $mattached_path = "/opt/nvidia/hpc_sdk/Linux_x86_64/23.7/comm_libs/12.2/openmpi4/openmpi-4.1.5/bin:/opt/nvidia/hpc_sdk/Linux_x86_64/23.7/compilers/bin:/opt/nvidia/hpc_sdk/Linux_x86_64/23.7/cuda/12.2/bin";#attached path in main script

#/opt/nvidia/hpc_sdk/Linux_x86_64/23.7/comm_libs/12.2/openmpi4/openmpi-4.1.5/bin/mpif90

#path_setting($mattached_path);
#/opt/intel/compilers_and_libraries_2018.0.128/linux/mkl/lib/intel64_lin
#my $mattached_ld = "/opt/slurm_mvapich2-2.3.4/lib:/opt/intel/mkl/lib/intel64";#attached ld path in main script
#my $mattached_ld = "/opt/mpich-3.3.2/lib:/opt/intel/mkl/lib/intel64";#attached ld path in main script
my $mattached_ld = "/opt/nvidia/hpc_sdk/Linux_x86_64/23.7/comm_libs/12.2/openmpi4/openmpi-4.1.5/lib:/opt/intel/mkl/lib/intel64";#attached ld path in main script
ld_setting($mattached_ld);

#!/bin/sh
use warnings;
use strict;
use Cwd; #Find Current Path

my $CUDA_HOME = '"/opt/nvidia/hpc_sdk/Linux_x86_64/23.7/cuda/12.2"';
my $cuda_cc = '86';
my $cuda_runtime = '12.0';
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
my $prefix = "/opt/QE_GPU";
my $package = "q-e";
my $URL = "https://gitlab.com/QEF/q-e.git";#url to download
my $Dir4download = "$packageDir/qeGPU_download"; #the directory we download Mpich

my $script_CurrentPath = getcwd(); #get perl code path
if($wgetORgit eq "yes"){
	system("rm -rf $Dir4download");# remove the older directory first
	system("mkdir $Dir4download");# make a directory in current path

##download qe 
	chdir("$Dir4download");# cd to this dir for downloading the packages
##get the latest package in the directory and save it as the filename you want
	system("git clone $URL"); # download qe
	if($?){die "wget $URL failed!!\n";} 
	chdir("$script_CurrentPath");

} 


chdir("$Dir4download/q-e");# cd to this dir for downloading the packages

my $prefix4QE = "--prefix=$prefix";
system("rm -rf $prefix");

#system("./configure $prefix F90=ifort F77=mpiifort MPIF90=mpiifort CC=mpiicc $BLAS_LIBS $LAPACK_LIBS $SCALAPACK_LIBS $FFT_LIBS $FFLAGS $MPI_LIBS --enable-parallel");
# find all threads to make this package
my $thread4make = `nproc`;
chomp $thread4make;
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
#system("./configure  $FFLAGS $prefix4QE");
system("./configure F90=nvfortran CC=nvc CXX=nvc++ --enable-parallel --enable-openmp --with-cuda=$CUDA_HOME --with-cuda-cc=$cuda_cc --with-cuda-runtime=$cuda_runtime $prefix4QE --libdir=/opt/nvidia/hpc_sdk/Linux_x86_64/23.7/math_libs/12.2");
#./configure F90=nvfortran CC=nvc CXX=nvc++ --enable-parallel --enable-openmp --with-cuda=/opt/nvidia/hpc_sdk/Linux_x86_64/23.7/cuda --with-cuda-cc=86 --with-cuda-runtime=12.0 --prefix=/opt/QE_GPU
#--with-cuda=$CUDA_HOME --with-cuda-cc=70 --with-cuda-runtime=11.0
if($?){die "**QE configure fails!\nReason:$?\n";}
#after the configure process is done, type "make" and then "make install"
system("make clean"); 
if($?){die "**make QE clean fails";}
system("make pwall -j $thread4make");
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
