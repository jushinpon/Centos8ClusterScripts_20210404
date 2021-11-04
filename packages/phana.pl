#developed by Prof. Shin-Pon Ju (2021/Nov/1)
#Perl script to Downlaod and install phana 
# You need to be root to use this script
#1. You need go to https://github.com/lingtikong/phana to check the latest phana version 
#yum install glibc glibc-devel
#yum install -y libstdc++*
# yum install glibc-static
#need to modify path for make file
####set environment variables for path and lib (only works in this script)
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
my $mattached_path = "/opt/mpich-3.4.2/bin";#attached path in main script
path_setting($mattached_path);#:/opt/intel/mkl/lib/intel64
#my $mattached_ld = "/opt/mpich-3.3.2/lib";#attached ld path in main script
#my $mattached_ld = "/opt/clapack/3.2.1/lib";#attached ld path in main script
#ld_setting($mattached_ld);

use warnings;
use strict;
use Cwd; #Find Current Path

my $wgetORgit = "yes";

my $packageDir = "/home/packages";
if(!-e $packageDir){# if no /home/packages, make this folder	
	system("mkdir $packageDir");	
}

my $thread4make = `lscpu|grep "^CPU(s):" | sed 's/^CPU(s): *//g'`;
chomp $thread4make;
print "Total threads can be used for make: $thread4make\n";

#install fftw
my $URL = "https://github.com/lingtikong/phana.git";#url to download
my $Dir4download = "$packageDir/phana_download"; #the directory we download Mpich
my $currentPath = getcwd(); #get perl code path
####### in the directory of $lammps_download
if($wgetORgit eq "yes"){
	#system ("rm -rf $Dir4download");# remove the older directory first
	#system("mkdir $Dir4download");# make a directory in current path
	#
	chdir("$Dir4download");# cd to this dir for downloading the packages
	#system("git clone $URL");
	my $temp = `find ./ -maxdepth 1 -mindepth 1 -type d -name "*"|awk -F'/' '{print \$NF}'`;
    chomp $temp;
	print "temp: $temp\n";
	chdir("$Dir4download/$temp/libs");# cd to this dir for downloading the packages
	system("tar xvzf clapack.tgz");
	chdir("$Dir4download/$temp/libs/CLAPACK-3.2.1");# cd to this dir for downloading the packages
	system("cp make.inc.example make.inc");
	system("make lib");
	#copy and link
	system("mkdir -p /opt/clapack/3.2.1/lib");
	system("cp -r INCLUDE /opt/clapack/3.2.1/include");
	system("cp *.a /opt/clapack/3.2.1/lib/");
	system("cp F2CLIBS/*.a /opt/clapack/3.2.1/lib/");
	`rm -f /opt/clapack/3.2.1/lib/libblas.a`;
	`rm -f /opt/clapack/3.2.1/lib/liblapack.a`;
	#`rm -f /opt/clapack/3.2.1/lib/libclapack.a`;
	system("ln -s /opt/clapack/3.2.1/lib/blas_LINUX.a  /opt/clapack/3.2.1/lib/libblas.a");
	system("ln -s /opt/clapack/3.2.1/lib/lapack_LINUX.a  /opt/clapack/3.2.1/lib/liblapack.a");
	#system("ln -s /opt/clapack/3.2.1/lib/clapack_LINUX.a /opt/clapack/3.2.1/lib/libclapack.a");
    
#Installation of libtricubic:
	#chdir("$Dir4download/$temp/libs");# cd to this dir for downloading the packages
	#system("tar xvzf tricubic-1.0.tgz");
	#chdir("$Dir4download/$temp/libs/tricubic-1.0");# cd to this dir for downloading the packages
	#system("./configure --prefix=/opt/tricubic/1.0");
	#system("make -j $thread4make");
	#system("make install");
	chdir("$Dir4download/$temp");# cd to this dir for downloading the packages
	system("make clean");
	system("make");
	`rm -rf /opt/phana`;
	`mkdir -p /opt/phana`;
	`cp phana /opt/phana/`;
	`chmod 755 /opt/phana/phana`;

}
print "*******PHana DONE!\n";
