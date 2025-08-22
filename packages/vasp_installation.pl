#mklpath = /opt/intel/oneapi/mkl/2025.0
#export PATH=$PATH:/path/to/vasp.x.x.x/bin
#export LD_LIBRARY_PATH=/opt/hdf5/lib:$LD_LIBRARY_PATH
#ldd /opt/vasp/bin/vasp_std

########need to do it before compiling ########
#source /opt/intel/oneapi/setvars.sh

#tar -xzf hdf5-1.14.3.tar.gz
#cd hdf5-1.14.3
#./configure --prefix=/opt/hdf5 --enable-fortran --enable-parallel
#make -j$(nproc)
#sudo make install
#https://github.com/HDFGroup/hdf5.git
#https://www.hdfgroup.org/download-hdf5/source-code/#

#!/usr/bin/perl
use strict;
use warnings;
use Cwd qw/getcwd abs_path/;
use POSIX qw(strftime);


#!/usr/bin/perl
use strict;
use warnings;

my $CurrentPath = getcwd(); #get perl code path
my $install_dir = "/opt/vasp-6.4.3"; # VASP installation directory
my $unzip = "yes"; # Set to 'yes' to automatically unzip the tarball
my $MKLROOT = `echo \$MKLROOT`;
chomp($MKLROOT);
die "MKLROOT is not set. Please set it to your Intel MKL installation path. Source the sh file" unless $MKLROOT;

my $packageDir = "/home/packages/vasp";
my $src_tarball      = "$packageDir/vasp.6.4.3.tgz";
my $src_unpacked     = "vasp.6.4.3";  # expected unpacked dir name
die "Source tarball not found: $src_tarball" unless -e $src_tarball;
`rm -rf $packageDir/$src_unpacked`;  # Clean up any existing unpacked directory
if ($unzip eq "yes") {
    chdir($packageDir) or die "Cannot change directory to $packageDir: $!";
    print "Removing existing unpacked directory $src_unpacked...\n";
    `rm -rf $src_unpacked`;  # Clean up any existing unpacked directory
    die "Failed to remove existing directory $src_unpacked" if $? != 0;
    print "Unzipping $src_tarball...\n";
    system("tar -xzf $src_tarball");
    die "Failed to unzip $src_tarball" if $? != 0;
    chdir($CurrentPath) or die "Cannot change back to $CurrentPath: $!";
    #`cp ./vasp_oneapi_makefile.include $packageDir/$src_unpacked/makefile.include`; # Copy the custom makefile
}   
die;
chdir($CurrentPath) or die "Cannot change back to $CurrentPath: $!";

my $makefile_template = "$packageDir/$src_unpacked/arch/makefile.include.oneapi";
#system("cat $makefile_template");  # Display the template content for debugging

die "Makefile template not found: $makefile_template" unless -e $makefile_template;
my $makefile = "$packageDir/$src_unpacked/makefile.include";
unlink $makefile if -e $makefile;  # Remove existing makefile if it exists
print "Copying makefile template to $makefile...$makefile_template\n";
system("cp $makefile_template $makefile");
#cp $makefile_template $makefile
die "Failed to copy makefile template" unless (-e $makefile);

# 1. Set MKLROOT path
system("sed -i 's|^MKLROOT.*|MKLROOT    ?= $MKLROOT|' $makefile");
if($?){die "Failed to set MKLROOT in $makefile\n";}

# 2. Uncomment and append -DVASP_HDF5 to CPP_OPTIONS (if not already added)
system("sed -i 's|^#CPP_OPTIONS[[:space:]]\\+\\+=[[:space:]]\\+-DVASP_HDF5|CPP_OPTIONS+= -DVASP_HDF5|' $makefile");
if($?){die "Failed to set CPP_OPTIONS in $makefile\n";}

# 3. Uncomment and set HDF5_ROOT
system("sed -i 's|^#HDF5_ROOT[[:space:]]\\+\\?=.*|HDF5_ROOT  ?= /opt/hdf5|' $makefile");
if($?){die "Failed to set HDF5_ROOT in $makefile\n";}

# 4. Uncomment HDF5 LLIBS line and set actual path
system("sed -i 's|^#LLIBS[[:space:]]\\+\\+=[[:space:]]\\+-L\\\$(HDF5_ROOT)/lib -lhdf5_fortran|LLIBS      += -L\\\$(HDF5_ROOT)/lib -lhdf5_fortran|' $makefile");

# 5. Uncomment and update HDF5 INCS line
system("sed -i 's|^#INCS[[:space:]]\\+\\+=[[:space:]]\\+-I\\\$(HDF5_ROOT)/include|INCS       += -I\\\$(HDF5_ROOT)/include|' $makefile");

# Comment the VASP_TARGET_CPU definition line
system("sed -i 's/^\\s*VASP_TARGET_CPU\\s*\\?=/#&/' $makefile");

# Comment the FFLAGS addition line for VASP_TARGET_CPU
system("sed -i 's/^\\s*FFLAGS\\s*\\+=\\s*\\\$(VASP_TARGET_CPU)/#&/' $makefile");
die;
my $cpu_num = `nproc`;
chomp($cpu_num);
my $make_cmd = "cd $packageDir/$src_unpacked && make -j$cpu_num";   
system("$make_cmd");

die "Failed to compile VASP" if $? != 0;
`rm -rf $install_dir`;  # Clean up any existing installation directory
mkdir $install_dir or die "Failed to create installation directory: $install_dir" unless -d $install_dir;
`cp -r $packageDir/$src_unpacked/bin/* $install_dir/bin/`;  # Copy binaries to installation directory
`cp -r $packageDir/$src_unpacked/lib/* $install_dir/lib/`;
`cp -r $packageDir/$src_unpacked/include/* $install_dir/include/`;

