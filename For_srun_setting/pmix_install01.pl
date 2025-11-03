#!/usr/bin/perl
use strict;
use warnings;
use Cwd;

system("sudo dnf install -y libevent libevent-devel hwloc hwloc-devel");
# PMIx version (set manually here)
my $pmix_version = "4.2.9";
my $install_dir  = "/opt/pmix";
my $package_dir  = "/home/packages";
my $build_dir    = "$package_dir/pmix_build";
my $tarball      = "pmix-$pmix_version.tar.gz";
my $url          = "https://github.com/openpmix/openpmix/releases/download/v$pmix_version/$tarball";
my $src_dir      = "$build_dir/pmix-$pmix_version";
my $prefix       = "$install_dir/$pmix_version";

# detect cores
my $nproc = `nproc`; chomp $nproc;
$nproc = 4 if !$nproc;

print ">>> Installing PMIx $pmix_version with $nproc threads\n";

# make dirs
system("mkdir -p $package_dir $build_dir $install_dir");

chdir($build_dir) or die "Cannot cd to $build_dir: $!\n";

# download tarball
if (! -e $tarball) {
    system("wget $url") == 0 or die "Download failed: $!\n";
} else {
    print ">>> Found $tarball, skipping download\n";
}

# extract
if (-d $src_dir) { system("rm -rf $src_dir"); }
system("tar -xzf $tarball") == 0 or die "Extraction failed\n";

# build
chdir($src_dir) or die "Cannot cd to $src_dir: $!\n";
system("./configure --prefix=$prefix") == 0 or die "Configure failed\n";
system("make -j $nproc") == 0 or die "Make failed\n";
system("make install") == 0 or die "Make install failed\n";

# symlink
system("rm -f $install_dir/current");
system("ln -s $prefix $install_dir/current");

# add to ldconfig
open my $fh, ">>", "/etc/ld.so.conf.d/pmix.conf";
print $fh "$prefix/lib\n";
close $fh;
system("ldconfig");

print ">>> PMIx $pmix_version installed successfully under $prefix\n";
print ">>> Symlink available: $install_dir/current\n";
