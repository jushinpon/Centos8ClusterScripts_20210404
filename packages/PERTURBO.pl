=Developed by Prof. Shin-Pon Ju at NSYSU Oct.09 2020

1. Perl script to compile and install QE with PERTURBO. 
(https://perturbo-code.github.io/mydoc_installation.html)
@ARGV = ("yes","yes","yes","yes","yes","yes");  for qe, wannier, hdf5, perturbo, make softlink,MKL
1. leave perturbo no first
2. upload perturbo source after all installed
3. leave perturbo yes only
4. If all packages are done, make yes for soft link only.
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
my $mattached_path = "/opt/mpich-4.0.3/bin";#attached path in main script
path_setting($mattached_path);
#/opt/intel/compilers_and_libraries_2018.0.128/linux/mkl/lib/intel64_lin
#my $mattached_ld = "/opt/slurm_mvapich2-2.3.4/lib:/opt/intel/mkl/lib/intel64";#attached ld path in main script
#my $mattached_ld = "/opt/mpich-3.3.2/lib:/opt/intel/mkl/lib/intel64";#attached ld path in main script
my $mattached_ld = "/opt/mpich-4.0.3/lib:/opt/intel/mkl/lib/intel64";#attached ld path in main script
ld_setting($mattached_ld);
#my $mattached_ld = "/opt/lapack";#attached ld path in main script
#ld_setting($mattached_ld);

#!/bin/sh
use warnings;
use strict;
use Cwd; #Find Current Path

my $thread4make = `lscpu|grep "^CPU(s):" | sed 's/^CPU(s): *//g'`;
print "Total threads can be used for make: $thread4make\n";

my $qe = "$ARGV[0]";## if you want to download the QE source, use yes. Set no, if you have downloaded the source.
my $wannier = "$ARGV[1]";#install Wannier 90
my $hdf5 = "$ARGV[2]";#install hdf5
my $pertubo = "$ARGV[3]";#install perturbo
my $softlink = "$ARGV[4]";#make soft link for all required files
my $mkl = "$ARGV[5]";#dnf for MKL packages

my $packageDir = "/home/packages";
if(!-e $packageDir){# if no /home/packages, make this folder	
	system("mkdir $packageDir");	
}

###install intel MKL
if($mkl eq "yes"){
	system("yum -y install yum-utils");
	system("yum-config-manager --add-repo https://yum.repos.intel.com/mkl/setup/intel-mkl.repo");
	if($?){die "add intel repo failed!\n";}
	system("rpm --import https://yum.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB");
	if($?){die "import intel repo key failed!\n";}
	system("yum install -y intel-mkl");
}
#my $prefix = "/opt/QEGCC_MPICH3.3.2_thermoPW";
my $prefix = "/opt/PERTURBO";
my $package = "qe4perturbo";
#my $currentVer = "qe-6.5.tar.gz";#***** the latest version of this package (check the latest one if possible)
my $currentVer = "qe-7.0.tar.gz";#***** the latest version of this package (check the latest one if possible)
#my $unzipFolder = "q-e-qe-6.5";#***** the unzipped folder of this package (check the latest one if possible)
my $unzipFolder = "q-e-qe-7.0";#***** the unzipped folder of this package (check the latest one if possible)
#my $URL = "https://github.com/QEF/q-e/archive/qe-6.5.tar.gz";#url to download
my $URL = "https://github.com/QEF/q-e/archive/refs/tags/qe-7.0.tar.gz";#url to download
my $Dir4download = "$packageDir/qe4perturbo_download"; #the directory we download Mpich
my $script_CurrentPath = getcwd(); #get perl code path

chdir("$script_CurrentPath");# cd to this dir for downloading the packages
if($qe eq "yes"){
	system("rm -rf $Dir4download");# remove the older directory first
	system("mkdir $Dir4download");# make a directory in current path
##download qe and thermo_pw
	chdir("$Dir4download");# cd to this dir for downloading the packages
##get the latest package in the directory and save it as the filename you want
	system("wget $URL"); # download qe
	if($?){die "wget $URL failed!!\n";} 

	system("rm -rf $unzipFolder");
	system("tar xvzf $currentVer");#unzip qe
	if($?){die "tar xvzf $currentVer failed!!\n";} 

	if(! -d "$Dir4download/$unzipFolder" ){
		die "No $unzipFolder folder after tar! You need to find the correct folder name\n";
	}
	chdir("$Dir4download/$unzipFolder");# cd to this dir for downloading the packages
	my $FFLAGS="FFLAGS=\"-O3 \"";
	system("./configure --enable-parallel  $FFLAGS");
	if($?){die "**QE configure fails!\nReason:$?\n";}
	#after the configure process is done, type "make" and then "make install"
	system("make clean"); 
	if($?){die "**make QE clean fails";}
	system("make pw ph pp -j $thread4make");
	system("ls bin");
	#chdir("$script_CurrentPath");
} 

if($wannier eq "yes"){
	`dnf install lapack-devel -y`;
	chdir("$Dir4download/$unzipFolder");# cd to this dir for downloading the packages
	`wget https://github.com/wannier-developers/wannier90/archive/v3.0.0.tar.gz`;
	`tar xvzf v3.0.0.tar.gz`;
	chdir("$Dir4download/$unzipFolder/wannier90-3.0.0");# cd to this dir for downloading the packages
	`cp ./config/make.inc.gfort ./make.inc`;
	system("make clean");
	system("make -j $thread4make");
}

if($hdf5 eq "yes"){
	chdir("$Dir4download/$unzipFolder");# cd to this dir for downloading the packages
	`wget  wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.12/hdf5-1.12.0/src/hdf5-1.12.0.tar.gz`;
	`tar xvzf  hdf5-1.12.0.tar.gz`;
	chdir("$Dir4download/$unzipFolder/hdf5-1.12.0");# cd to this dir for downloading the packages
	`rm -rf /opt/hdf5`;
	`mkdir -p /opt/hdf5`;
	`./configure --prefix=/opt/hdf5 --enable-fortran `;
	system("make clean");
	system("make -j $thread4make");
	system("make install");
}

if($pertubo eq "yes"){
	chdir("$Dir4download/$unzipFolder/perturbo-2.0.2");# cd to this dir for downloading the packages
	system("make clean");
	system("make -j $thread4make");
}

if($softlink eq "yes"){
	`rm -rf /opt/qe4perturbo`;
	`mkdir /opt/qe4perturbo`;
	`mkdir /opt/qe4perturbo/qe`;
	`mkdir /opt/qe4perturbo/wannier`;
	`mkdir /opt/qe4perturbo/perturbo`;
	
	`ln -f -s '/home/packages/qe4perturbo_download/q-e-qe-7.0/bin' '/opt/qe4perturbo/qe'`;#qe dir
	`ln -f -s '/home/packages/qe4perturbo_download/q-e-qe-7.0/wannier90-3.0.0/wannier90.x' '/opt/qe4perturbo/wannier/wannier90.x'`;#
	`ln -f -s '/home/packages/qe4perturbo_download/q-e-qe-7.0/wannier90-3.0.0/postw90.x' '/opt/qe4perturbo/wannier/postw90.x'`;#
	`ln -f -s /home/packages/qe4perturbo_download/q-e-qe-7.0/perturbo-2.0.2/bin /opt/qe4perturbo/perturbo`;#
#ln -s /my/long/path/to/the/directory easyPath
	`chmod 755 -R /opt/qe4perturbo`;
}

#
#chdir("$Dir4download");# cd to this dir for downloading the packages
#  
##system("make pw -j $thread4make"); 
##system("make all -j $thread4make"); #cp.x
##if($?){die "make qe failed!\nReason:$?\n";}
#system("make install"); 
##if($?){die "make install failed!\n";}
#print "QE with thermo_pw has been successfully installed!!\n";
#print "\n\nCheck thermo_pw.x in $prefix/bin!! \n\n";
#system("ls $prefix/bin"); 
##if(!-e "/opt/QEsssp"){# if no /home/packages, make this folder	
##	system("mkdir /opt/QEsssp");	
##	system("mkdir /opt/QEsssp/Efficiency");	
##	system("mkdir /opt/QEsssp/Precision");	
##}
#
#print "\n*****You need to download SSSP potential for QE!!\n";
#