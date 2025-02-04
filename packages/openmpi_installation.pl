#!/usr/bin/perl
use strict;
use warnings;
use Cwd; # Get current working directory

# Define installation directories
my $packageDir = "/home/packages";
my $openmpi_version = "5.0.6";
my $prefixPath = "/opt/openmpi-$openmpi_version";
my $URL = "https://download.open-mpi.org/release/open-mpi/v5.0/openmpi-$openmpi_version.tar.gz";
# Create package directory if it doesn't exist
system("mkdir -p $packageDir") unless -d $packageDir;

# Detect CPU cores for parallel compilation
my $num_threads = `nproc`;
chomp $num_threads;
print "Using $num_threads CPU threads for compilation...\n";

# Set download and extraction directory
my $Dir4download = "$packageDir/openmpi_download";
system("rm -rf $Dir4download");
system("mkdir -p $Dir4download");

# Function to check if a package is installed
sub check_package {
    my $pkg = shift;
    my $status = `dnf list installed $pkg 2>/dev/null | grep -c $pkg`;
    chomp $status;
    return $status;
}

# Required packages for OpenMPI
my @packages = (
    "gcc", "gcc-c++", "gcc-gfortran", "make", "perl",
    "hwloc-devel", "libevent-devel", "numactl-devel",
    "pmix", "pmix-devel"
);

# Check for missing packages and install them if user agrees
my @missing_packages = ();
foreach my $pkg (@packages) {
    if (check_package($pkg) == 0) {
        push @missing_packages, $pkg;
    }
}

if (@missing_packages) {
    print "The following packages are missing: @missing_packages\n";
    print "Do you want to install them? (y/n): ";
    my $answer = <STDIN>;
    chomp $answer;
    if ($answer eq "y") {
        system("sudo dnf install -y @missing_packages");
        if ($? != 0) { die "Failed to install required packages!\n"; }
    } else {
        die "Missing dependencies. Exiting installation.\n";
    }
}

# Change to download directory
chdir("$Dir4download") or die "Failed to change directory: $!\n";

# Download OpenMPI source code
print "Downloading OpenMPI $openmpi_version...\n";
system("wget -q --show-progress $URL");
die "Download failed!\n" if $? != 0;

# Extract OpenMPI
print "Extracting OpenMPI...\n";
system("tar -xzf openmpi-$openmpi_version.tar.gz");
die "Extraction failed!\n" if $? != 0;

# Change to source directory
chdir("$Dir4download/openmpi-$openmpi_version") or die "Failed to enter OpenMPI source directory: $!\n";

# Remove any existing installation
system("rm -rf $prefixPath");

# Configure OpenMPI **without Infiniband**
print "Configuring OpenMPI (without Infiniband)...\n";
my $config_command = "./configure --prefix=$prefixPath --enable-mpi-thread-multiple --without-verbs --without-ucx --without-libfabric --with-pmix";
system($config_command);
die "Configuration failed!\n" if $? != 0;

# Compile OpenMPI
print "Compiling OpenMPI with $num_threads threads...\n";
system("make clean");
system("make -j$num_threads");
die "Compilation failed!\n" if $? != 0;

# Install OpenMPI
print "Installing OpenMPI...\n";
system("make install");
die "Installation failed!\n" if $? != 0;

# Set environment variables
#print "Updating environment variables...\n";
#my $env_file = "/etc/profile.d/openmpi.sh";
#open(my $fh, '>', $env_file) or die "Failed to open file: $!\n";
#print $fh <<EOF;
#export PATH=$prefixPath/bin:\$PATH
#export LD_LIBRARY_PATH=$prefixPath/lib:\$LD_LIBRARY_PATH
#export MANPATH=$prefixPath/share/man:\$MANPATH
#EOF
#close($fh);
#
## Apply changes
#system("source $env_file");

# Verify installation
print "Verifying OpenMPI installation...\n";
system("$prefixPath/bin/mpirun --version");

print "\n✅ OpenMPI $openmpi_version successfully installed at $prefixPath!\n";
