#!/usr/bin/perl
use strict;
use warnings;
use Cwd;

my $install_dir = "/opt/pmix";
my $package_dir = "/home/packages";
my $build_dir   = "$package_dir/pmix_build";
my $libevent_prefix = "/opt/libevent";

my $pmix_version = "4.2.9";   # <-- set manually
my $tarball = "pmix-$pmix_version.tar.gz";
my $prefix = "$install_dir/$pmix_version";

# --- detect cores ---
chomp(my $nproc = `nproc` || 4);

# --- ensure dirs ---
system("mkdir -p $package_dir $build_dir $install_dir");

# --- ensure libevent exists ---
if (! -f "$libevent_prefix/lib/libevent_core-2.1.so.7") {
    die "libevent not found under $libevent_prefix/lib. Install it first!\n";
}

# --- go to build dir ---
chdir($build_dir) or die "Cannot cd to $build_dir: $!\n";

if (! -e $tarball) {
    die "Local tarball $tarball not found in $build_dir!\nPlease copy it there first.\n";
}
print ">>> Found local tarball: $tarball\n";

system("rm -rf pmix-$pmix_version");
system("tar -xzf $tarball") == 0 or die "Extraction failed: $!\n";
chdir("pmix-$pmix_version") or die "Cannot cd to source dir\n";

# --- build ---
print ">>> Configuring PMIx $pmix_version with libevent=$libevent_prefix\n";
system("./configure --prefix=$prefix --with-libevent=$libevent_prefix") == 0 or die "Configure failed: $!\n";
system("make clean");
system("make -j $nproc") == 0 or die "Make failed: $!\n";
system("make install") == 0 or die "Install failed: $!\n";

# --- link & register ---
system("ln -sfn $prefix $install_dir/current");
system("echo '$prefix/lib' > /etc/ld.so.conf.d/pmix.conf");
system("ldconfig");

print ">>> PMIx $pmix_version installed successfully in $prefix\n";
print ">>> Use: export LD_LIBRARY_PATH=$install_dir/current/lib:\$LD_LIBRARY_PATH\n";
