=b
Perl script to Downlaod and install mvapich2 (developed by Prof. Shin-Pon Ju)

only the following adpter cards are supported:  	
#define MV2_STR_MLX          "mlx"	 	#define MV2_STR_MLX          "mlx"
#define MV2_STR_MLX4         "mlx4"	 	#define MV2_STR_MLX4         "mlx4"
#define MV2_STR_MLX5         "mlx5"	 	#define MV2_STR_MLX5         "mlx5"
#define MV2_STR_MTHCA        "mthca"	 	#define MV2_STR_MTHCA        "mthca"
#define MV2_STR_IPATH        "ipath"	 	#define MV2_STR_IPATH        "ipath"
#define MV2_STR_QIB          "qib"	 	#define MV2_STR_QIB          "qib"
#define MV2_STR_HFI1         "hfi1"	 	#define MV2_STR_HFI1         "hfi1"
#define MV2_STR_EHCA         "ehca"	 	#define MV2_STR_EHCA         "ehca"
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
#my $mattached_path = "/opt/mpich-3.3.2/bin";#attached path in main script
#path_setting($mattached_path);
my $mattached_ld = "/usr/local/lib";#attached ld path in main script
ld_setting($mattached_ld);

use warnings;
use strict;
use Env::Modify qw(:sh source);
use Cwd; #Find Current Path
use File::Copy; # Copy File

my $wgetORgit = "yes";#yes or no

my $packageDir = "/home/packages";
if(!-e $packageDir){# if no /home/packages, make this folder	
	system("mkdir $packageDir");	
}

my $current_path = getcwd();# get the current path dir

# find all threads to make this package
my $thread4make = `lscpu|grep "^CPU(s):" | sed 's/^CPU(s): *//g'`;
chomp $thread4make;
print "Total threads can be used for make: $thread4make\n";

my $currentVer = "mvapich2-2.3.5";#***** the latest version of this package
#my $prefixPath = "/opt/$currentVer-mrail";#/opt/slurm_$currentVer if works with slurm
my $prefixPath = "/opt/$currentVer-srunMrail";#/opt/slurm_$currentVer if works with slurm
chomp $prefixPath;
system ("rm -rf $prefixPath");# remove the older directory first
my $URL = "http://mvapich.cse.ohio-state.edu/download/mvapich/mv2/mvapich2-2.3.5.tar.gz";
my $Dir4download = "$packageDir/$currentVer-4slurm_download"; #the directory we download MPICH

###
if($wgetORgit eq "yes"){
	system ("rm -rf $Dir4download");# remove the older directory first
	system("mkdir $Dir4download");# make a directory in current path
	
	chdir("$Dir4download");# cd to this dir for downloading the packages
	#get the latest package in the directory and save it as the filename you want
	system("wget $URL"); 
	if ($?){die "wget $currentVer $URL failed\n";}
	if(! (-e "$Dir4download/$currentVer.tar.gz")){die "No $currentVer downloaded";}# if no mpich file
	chdir("$current_path");# cd to this dir for downloading the packages

}

# tar -xvzf XXX(package name), and then cd this new folder	
chdir("$Dir4download");# cd to this dir for downloading the packages
system("rm -rf  $currentVer");
system("tar -xvzf $currentVer.tar.gz"); #$Ch =  Check
if ($?){die "tar -xvzf mvapich failed\n";} 
chdir("$current_path");# cd to this dir for downloading the packages

#
chdir("$Dir4download/$currentVer");#$currentVer is the directory name after tar
##$Ch = system("./configure CC=gcc CXX=g++ FC=gfortran --prefix=$Current_Path/$get_MPI_Folder/mpich-install --with-device=ch4:ofi"); #./configure
##system("./configure --prefix=$prefixPath"); #./configure
##./configure --prefix=$prefixPath --with-slurm=<PATH> --with-pmi=pmi2 --with-pmix=[/opt/pmix/install/2.1]
##LIBS="-l/usr/local/lib"
##CPPFLAGS= "-I/usr/local/include/slurm"/home/packages/mpich_download/mpich-3.3.2/src/pmi/pmi2/include 
unlink "Makefile";
sleep(1);
#--enable-fast=all,O3 --with-slurm-include=/usr/local/include/slurmCPPFLAGS=-I/home/packages/mpich_download/mpich-3.3.2/src/pmi/pmi2/include
#:--with-device=ch3:sock  for 1G ether card --with-pm=slurm --with-pmi=pmi2
#--with-device=ch3:mrail --with-rdma=gen2
#--with-device=ch3:nemesis
#system("./configure --with-device=ch3:mrail --with-rdma=gen2 --prefix=$prefixPath --enable-g=dbg --enable-debuginfo");
#system("./configure --with-device=ch3:sock --prefix=$prefixPath --enable-g=dbg --enable-debuginfo");
#system("./configure --with-device=ch3:nemesis --prefix=$prefixPath --enable-g=dbg --enable-debuginfo");
#system("./configure --with-device=ch3:nemesis:ib,tcp --with-rdma=gen2 --prefix=$prefixPath --enable-g=dbg --enable-debuginfo");
system("./configure --enable-slurm=yes --prefix=$prefixPath --with-pm=slurm --with-pmi=pmi2 --with-slurm=/usr/local --with-slurm-include=/usr/local/include/slurm --with-device=ch3:mrail --with-rdma=gen2");# --with-slurm=[/usr/local] VERBOSE=1 |tee 00mpich_configure.txt"); #./configure
if($?){die "config $currentVer failed!\nReason $?:$!\n";}
#die"configure completed\n";
#after the configure process is done, type "make" and then "make install"
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
#print "**** source /etc/profile is required!!!!\n";
#source("/etc/profile");
