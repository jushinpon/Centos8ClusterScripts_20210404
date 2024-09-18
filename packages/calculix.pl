# Perl script to install CalculiX 2.21 from scratch on Rocky Linux 8
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
my $mattached_path = "/opt/mpich-4.0.3/bin";#attached path in main script
path_setting($mattached_path);
#/opt/intel/compilers_and_libraries_2018.0.128/linux/mkl/lib/intel64_lin
my $mattached_ld = "/opt/mpich-4.0.3/lib:/opt/intel/mkl/lib/intel64";#attached ld path in main script
ld_setting($mattached_ld);

#!/bin/sh

use warnings;
use strict;
use Cwd; # Current Path

my $packageDir = "/home/packages"; # Declare the variable at the script level


# Download and unpack CalculiX
my $calculix_url = "http://www.dhondt.de/ccx_2.21.src.tar.bz2";
my $calculix_tar = "ccx_2.21.src.tar.bz2";
my $calculix_dir = "$packageDir/calculix";

chdir $packageDir;
system("wget $calculix_url");
system("tar -xjf $calculix_tar");

chdir "CalculiX/ccx_2.21/src";
system("make -j 4"); # Adjust -j parameter based on your CPU cores for parallel compilation

# Check if CalculiX compiled successfully
if (-e "ccx_2.21") {
    print "CalculiX installed successfully.\n";
} else {
    die "Failed to compile CalculiX.\n";
}

# Optionally, move the binary to a system-wide accessible location
# system("mv ccx_2.21 /usr/local/bin/");
