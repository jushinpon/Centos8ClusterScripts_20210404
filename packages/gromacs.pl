#Perl script to Downlaod and install gromacs (developed by Prof. Shin-Pon Ju (2021/Mar/01))
# You need to be root to use this script
#1. You need go to http://lammps.sandia.gov/tars/lammps.tar.gz to check the latest lammps version and set the downloading url
#2. compiling procedure
#a. make a directory to download the tar.gz file 
#b. get the source zip file and rename it as lammps file (wget -O lammps XXX)
#c. unziptar -xvzf
#d.do the necessary things

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
#my $mattached_path = "/opt/mpich-3.4.1/bin";#attached path in main script
#path_setting($mattached_path);#:/opt/intel/mkl/lib/intel64
#my $mattached_ld = "/opt/mpich-3.3.2/lib";#attached ld path in main script
#my $mattached_ld = "/opt/mpich-3.4.1/lib";#attached ld path in main script
#ld_setting($mattached_ld);

#my $mattached_path = "/opt/openmpi-4.1.0/bin";#attached path in main script
my $mattached_path = "/opt/mvapich2-2.3.5-srunMrail/bin";#attached path in main script
path_setting($mattached_path);#:/opt/intel/mkl/lib/intel64
#my $mattached_ld = "/opt/openmpi-4.1.0/lib";#attached ld path in main script
my $mattached_ld = "/opt/mvapich2-2.3.5-srunMrail/lib";#attached ld path in main script
ld_setting($mattached_ld);

use warnings;
use strict;
use Cwd; #Find Current Path
#use FindBin; #Find Path
use File::Copy; # Copy File
#use Env::Modify qw(:sh source);

my $wgetORgit = "yes";
my $packageDir = "/home/packages";
if(!-e $packageDir){# if no /home/packages, make this folder	
	system("mkdir $packageDir");	
}

my $thread4make = `lscpu|grep "^CPU(s):" | sed 's/^CPU(s): *//g'`;
chomp $thread4make;
print "Total threads can be used for make: $thread4make\n";

my $URL = "https://github.com/lammps/lammps.git";#url to download
#my $URL = "https://lammps.sandia.gov/tars/lammps.tar.gz";#url to download
my $Dir4download = "$packageDir/lammps_download"; #the directory we download Mpich
my $currentPath = getcwd(); #get perl code path








#get GROMACS
$GROMACS_URL = "http://ftp.gromacs.org/pub/gromacs/gromacs-5.1.5.tar.gz";
system("wget -O gromacs-5.1.5.tar.gz $GROMACS_URL");
system("tar xfz gromacs-5.1.5.tar.gz");
chdir("gromacs-5.1.5");
mkdir("build");
chdir("build");
system("cmake .. -DGMX_BUILD_OWN_FFTW=ON -DREGRESSIONTEST_DOWNLOAD=ON -DGMX_GPU=off");
system("make -j 8");
system("make check");
system("make install");

if(!`grep 'export PATH=/usr/local/gromacs/bin:\$PATH' /etc/profile`){
`echo 'export PATH=/usr/local/gromacs/bin:\$PATH' >> /etc/profile`;
}
print"######################\nPlease reboot\n######################\n";
