=b
https://wiki.mpich.org/mpich/index.php/Using_the_Hydra_Process_Manager
https://wiki.mpich.org/mpich/index.php/Testing_MPICH
 
=cut
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

my $mattached_path = "/opt/mpich-3.3.2/bin";#attached path in main script
path_setting($mattached_path);#:/opt/intel/mkl/lib/intel64
my $mattached_ld = "/opt/mpich-3.3.2/lib";#attached ld path in main script
ld_setting($mattached_ld);

#my $mattached_path = "/opt/openmpi-4.0.5/bin";#attached path in main script
#path_setting($mattached_path);#:/opt/intel/mkl/lib/intel64
#my $mattached_ld = "/opt/openmpi-4.0.5/lib";#attached ld path in main script
#ld_setting($mattached_ld);

use warnings;
use strict;
use Cwd; #Find Current Path
#use FindBin; #Find Path
use File::Copy; # Copy File

#system("HYDRA_TOPO_DEBUG=1 mpiexec -n 8 -bind-to hwthread /bin/true | sort -k 2 -n");
#sleep(10);
my $packageDir = "/home/packages";
my $currentVer = "mpich-3.3.2";#***** the latest version of this package
my $prefixPath = "/opt/$currentVer";
my $Dir4download = "$packageDir/mpich_download"; #the directory we download MPICH


chdir("$Dir4download/$currentVer");#$currentVer is the directory name after tar

##after the configure process is done, type "make" and then "make install"
system("make test-clean"); 
system("make testing"); 
sleep(1);


