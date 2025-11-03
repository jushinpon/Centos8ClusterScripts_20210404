#mklpath = /opt/intel/oneapi/mkl/2025.0
#export PATH=$PATH:/path/to/vasp.x.x.x/bin
#export LD_LIBRARY_PATH=/opt/hdf5-ifx/lib:$LD_LIBRARY_PATH
#ldd /opt/vasp/vasp_std

########need to do it before compiling ########
#source /opt/intel/oneapi/setvars.sh

#tar -xzf hdf5-1.14.3.tar.gz
#cd hdf5-1.14.3
#./configure --prefix=/opt/hdf5 --enable-fortran --enable-parallel
#make -j$(nproc)
#sudo make install
#https://github.com/HDFGroup/hdf5.git
#https://www.hdfgroup.org/download-hdf5/source-code/#

#vaspsol++
#https://github.com/VASPsol/VASPsol/tree/main

#current installation:vaspsol + vasp 6.4.3 + ifx + mkl + hdf5
#https://github.com/henniggroup/VASPsol
=b
1. cp VASPsol/src/solvation.F /path/to/vasp.6.4.3/src/

2. Edit .objects in your VASP source tree (no need to do for vasp.6.4.3)

.objects is in src/ and lists all object files.

Open it and look for pot.o (near the end of the list).

Insert solvation.o right before pot.o.

3. Add -Dsol_compat

4.From the VASP source root: patch -p0 < /path/to/VASPsol/patches/VASPsol6.patch
need to modify pot.F



5. make veryclean;make

=cut


#!/usr/bin/perl
use strict;
use warnings;
use Cwd qw/getcwd abs_path/;
use POSIX qw(strftime);


#!/usr/bin/perl
use strict;
use warnings;

my $CurrentPath = getcwd(); #get perl code path
my $install_dir = "/opt/vasp"; # VASP installation directory
my $unzip = "yes"; # Set to 'yes' to automatically unzip the tarball
my $MKLROOT = `echo \$MKLROOT`;
chomp($MKLROOT);
die "MKLROOT is not set. Please set it to your Intel MKL installation path. Source the sh file" unless $MKLROOT;

my $vaspsol_Dir = "/home/packages/vasp/VASPsol"; # VASPsol directory
`rm -rf $vaspsol_Dir`;  # Clean up any existing VASPsol directory
`cd /home/packages/vasp; git clone https://github.com/henniggroup/VASPsol`; # Clone VASPsol repository
die "Failed to clone VASPsol repository" if $? != 0;

my $packageDir = "/home/packages/vasp";
my $src_tarball      = "$packageDir/vasp.6.4.3.tgz";
my $src_unpacked     = "vasp.6.4.3";  # expected unpacked dir name
my $patch_file = "$packageDir/$src_unpacked/src/patches/pbz_patch_610"; # Patch file path
die "Source tarball not found: $src_tarball" unless -e $src_tarball;
#`rm -rf $packageDir/$src_unpacked`;  # Clean up any existing unpacked directory
if ($unzip eq "yes") {
    chdir($packageDir) or die "Cannot change directory to $packageDir: $!";
    print "Removing existing unpacked directory $src_unpacked...\n";
    `rm -rf $src_unpacked`;  # Clean up any existing unpacked directory
    die "Failed to remove existing directory $src_unpacked" if $? != 0;
    print "Unzipping $src_tarball...\n";
    system("tar -xzf $src_tarball");
    die "Failed to unzip $src_tarball" if $? != 0;
    chdir($CurrentPath) or die "Cannot change back to $CurrentPath: $!";
    `rm -f $packageDir/$src_unpacked/makefile.include`;  # Remove old makefile.include
    `cp ./makefile.include_ifx_sol_workable $packageDir/$src_unpacked/makefile.include`; # Copy the custom makefile
}   
#cp for vaspsol
`cp $vaspsol_Dir/src/solvation.F $packageDir/$src_unpacked/src/`;
`cp -R $vaspsol_Dir/patches $packageDir/$src_unpacked/src/`; #copy solvation folder
#apply patch 
`cd $packageDir/$src_unpacked/src/; patch -p0 < $patch_file`;
`cp /root/Centos8ClusterScripts_20210404/packages/modified_pot.F $packageDir/$src_unpacked/src/pot.F`; #replace pot.F
chdir($CurrentPath) or die "Cannot change back to $CurrentPath: $!";

#my $makefile_template = "$packageDir/$src_unpacked/arch/makefile.include.oneapi";
#system("cat $makefile_template");  # Display the template content for debugging

#die "Makefile template not found: $makefile_template" unless -e $makefile_template;
#my $makefile = "$packageDir/$src_unpacked/makefile.include";
#unlink $makefile if -e $makefile;  # Remove existing makefile if it exists
#print "Copying makefile template to $makefile...$makefile_template\n";
#system("cp $makefile_template $makefile");
#cp $makefile_template $makefile
#die "Failed to copy makefile template" unless (-e $makefile);

my $cpu_num = `nproc`;
chomp($cpu_num);
my $make_cmd = "cd $packageDir/$src_unpacked;make veryclean;make";   
system("$make_cmd");

die "Failed to compile VASP" if $? != 0;
`rm -rf $install_dir`;  # Clean up any existing installation directory
mkdir $install_dir or die "Failed to create installation directory: $install_dir" unless -d $install_dir;
`cp -r $packageDir/$src_unpacked/bin/* $install_dir/`;  # Copy binaries to installation directory
print "CHeck vasp with sol binary:\n";
system("ls $install_dir/vasp_*");
