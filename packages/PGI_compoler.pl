#Perl script to Downlaod and install pgi compiler (developed by Prof. Shin-Pon Ju (2021/Mar/01))
# You need to be root to use this script
#https://developer.nvidia.com/nvidia-hpc-sdk-downloads

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
#my $mattached_path = "/opt/mvapich2-2.3.5-srunMrail/bin";#attached path in main script
#path_setting($mattached_path);#:/opt/intel/mkl/lib/intel64
##my $mattached_ld = "/opt/openmpi-4.1.0/lib";#attached ld path in main script
#my $mattached_ld = "/opt/mvapich2-2.3.5-srunMrail/lib";#attached ld path in main script
#ld_setting($mattached_ld);
#
use warnings;
use strict;
use Cwd; #Find Current Path
use File::Copy; # Copy File

my $wgetORgit = "yes";
my $packageDir = "/home/packages";
if(!-e $packageDir){# if no /home/packages, make this folder	
	system("mkdir $packageDir");	
}

my $thread4make = `lscpu|grep "^CPU(s):" | sed 's/^CPU(s): *//g'`;
chomp $thread4make;
print "Total threads can be used for make: $thread4make\n";
my $Dir4download = "$packageDir/pgi_download"; #the directory we download Mpich
my $currentPath = getcwd(); #get perl code path
chdir("$Dir4download");
if($wgetORgit eq "yes"){
	system("wget https://developer.download.nvidia.com/hpc-sdk/21.2/nvhpc-21-2-21.2-1.x86_64.rpm");
	if($?)"first wget failed!\n";
	system("wget https://developer.download.nvidia.com/hpc-sdk/21.2/nvhpc-2021-21.2-1.x86_64.rpm");
	if($?)"second wget failed!\n";
	system("wget   https://developer.download.nvidia.com/hpc-sdk/21.2/nvhpc-21-2-cuda-multi-21.2-1.x86_64.rpm");
	if($?)"third wget failed!\n";
}

system("yum install -y ./nvhpc-21-2-21.2-1.x86_64.rpm");
if($?)"first installation failed!\n";
system("yum install -y ./nvhpc-2021-21.2-1.x86_64.rpm");
if($?)"second installation failed!\n";
system("yum install -y ./nvhpc-21-2-cuda-multi-21.2-1.x86_64.rpm");
if($?)"third installation failed!\n";
