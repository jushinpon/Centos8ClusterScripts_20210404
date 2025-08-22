#!/usr/bin/perl
=b
sudo dnf groupinstall -y "Development Tools"
sudo dnf install -y glibc-devel libstdc++-devel gcc gcc-c++ gcc-gfortran \
                    binutils m4 autoconf automake libtool cmake

source /opt/intel/oneapi/setvars.sh
export I_MPI_CC=icx
export I_MPI_CXX=icpx
export I_MPI_F90=ifx
export I_MPI_F77=ifx

=cut
use strict;
use warnings;
use Cwd qw/getcwd/;
use File::Path qw/make_path/;
use POSIX qw(strftime);

# ───────────── User settings ─────────────
my $use_download   = 1;   # 1=download, 0=use pre-downloaded tarball in $download_dir
my $version        = "1.14.6";
my $tar_name       = "hdf5-$version.tar.gz";
my $src_dir_name   = "hdf5-$version";
my $url            = "https://support.hdfgroup.org/releases/hdf5/v1_14/v1_14_6/downloads/$tar_name";
my $download_dir   = "/home/packages/hdf5_download";
my $install_prefix = "/opt/hdf5-ifx";  # keep separate from any gfortran build
# ─────────────────────────────────────────

sub run {
  my ($cmd) = @_;
  print "[CMD] $cmd\n";
  my $rc = system($cmd);
  if ($rc != 0) {
    my $code = $rc >> 8;
    die "[ERROR] Command failed (exit=$code): $cmd\n";
  }
}

# 0) Toolchain sanity: require Intel oneAPI + Intel MPI
my $MKLROOT = $ENV{MKLROOT} // "";
die "[ERROR] MKLROOT not set. Run: source /opt/intel/oneapi/setvars.sh\n" unless $MKLROOT;

for my $w (qw/mpiicc mpiicpc mpiifort ifx/) {
  my $which = `which $w 2>/dev/null`; chomp $which;
  die "[ERROR] $w not found in PATH. Did you source oneAPI? (source /opt/intel/oneapi/setvars.sh)\n" unless $which;
}

# 1) Prepare dirs and (optionally) download
make_path($download_dir) unless -d $download_dir;
chdir $download_dir or die "chdir $download_dir: $!";

if ($use_download) {
  unlink $tar_name if -e $tar_name;
  run("wget -O $tar_name '$url'");
} else {
  die "[ERROR] Tarball $tar_name not found in $download_dir\n" unless -e $tar_name;
}

# 2) Unpack fresh source
run("rm -rf $src_dir_name");
run("tar xzf $tar_name");
die "[ERROR] Missing source dir $src_dir_name after untar\n" unless -d $src_dir_name;

# 3) Backup any existing install instead of deleting it
if (-d $install_prefix) {
  my $ts = strftime("%Y%m%d-%H%M%S", localtime);
  my $bak = "${install_prefix}.bak.$ts";
  print "[INFO] Moving existing $install_prefix -> $bak\n";
  run("mv '$install_prefix' '$bak'");
}
make_path($install_prefix) unless -d $install_prefix;

# 4) Configure with Intel MPI wrappers + ifx Fortran
chdir $src_dir_name or die "chdir $src_dir_name: $!";

# You can also use CMake; here we stick to Autotools for simplicity
# Key: FC must be mpiifort with -fc=ifx so Fortran modules are ifx-compatible
$ENV{CC}  = "mpiicc";
$ENV{CXX} = "mpiicpc";
$ENV{FC}  = "mpiifort -fc=ifx";
$ENV{F77} = "mpiifort -fc=ifx";

# Optional optimization flags (tweak as desired)
$ENV{CFLAGS}   = "-O3";
$ENV{CXXFLAGS} = "-O3";
$ENV{FFLAGS}   = "-O3";
$ENV{FCFLAGS}  = "-O3";

my @cfg = (
  "./configure",
  "--prefix=$install_prefix",
  "--enable-parallel",
  "--enable-fortran",
  "--enable-fortran2003",
  "--enable-shared",
  # If your system needs explicit zlib path, add e.g.:
  # "--with-zlib=/usr",
);

run(join(" ", @cfg));

# 5) Build & install
my $n = `nproc`; chomp $n; $n ||= 4;
run("make -j$n");
run("make install");

# 6) Sanity checks
die "[ERROR] Missing $install_prefix/include/hdf5.mod\n"
  unless -e "$install_prefix/include/hdf5.mod";
die "[ERROR] Missing $install_prefix/lib/libhdf5_fortran.so\n"
  unless -e "$install_prefix/lib/libhdf5_fortran.so";

print "[OK] HDF5 installed at $install_prefix\n";

# 7) Tiny compile test to verify ifx can read the module
my $testf = "/tmp/t_h5.f90";
open my $fh, ">", $testf or die "write $testf: $!";
print $fh <<'F90';
program t
  use hdf5
  implicit none
  print *, "HDF5 Fortran module readable by ifx."
end program
F90
close $fh;

my $compile = "mpiifort -fc=ifx -I$install_prefix/include $testf ".
              "-L$install_prefix/lib -lhdf5_fortran -lhdf5 -lz -ldl -o /tmp/t_h5.x";
run($compile);

print "[OK] Test compile linked successfully. (Run /tmp/t_h5.x if desired.)\n";

print "\nNext steps for VASP:\n";
print "  1) Set HDF5_ROOT in makefile.include to: $install_prefix\n";
print "     HDF5_ROOT  ?= $install_prefix\n";
print "     INCS       += -I\$(HDF5_ROOT)/include\n";
print "     LLIBS      += -L\$(HDF5_ROOT)/lib -lhdf5_fortran -lhdf5 -lz -ldl\n";
print "     CPP_OPTIONS += -DVASP_HDF5\n";
print "  2) make veryclean; make -j$n std\n";
