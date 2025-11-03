#!/usr/bin/perl
# ==============================================================
#  Auto installer for libevent (for PMIx and Slurm)
#  Author: Prof. Shin-Pon Ju  |  Refined by ChatGPT (2025)
#  Version: 2025-10-07
# ==============================================================
use strict;
use warnings;
use Cwd;

# ---------------- CONFIG ----------------
my $version      = "2.1.12-stable";
my $prefix       = "/opt/libevent";
my $package_dir  = "/home/packages";
my $build_dir    = "$package_dir/libevent_build";
my $tarball      = "libevent-$version.tar.gz";
my $src_url      = "https://github.com/libevent/libevent/releases/download/release-$version/$tarball";
my $src_dir      = "$build_dir/libevent-$version";
my $ldconf_file  = "/etc/ld.so.conf.d/libevent.conf";

# ---------------- PREPARE ENV ----------------
print ">>> Preparing environment for libevent $version ...\n";
system("mkdir -p $package_dir $build_dir $prefix");

my $cwd = getcwd();

# Detect cores for parallel make
my $nproc = `nproc`;
chomp($nproc);
$nproc = 4 unless $nproc;
print ">>> Detected $nproc build threads\n";

# ---------------- DOWNLOAD ----------------
chdir($build_dir) or die "Cannot cd to $build_dir: $!\n";
if (-e $tarball) {
    print ">>> Found existing $tarball, skipping download.\n";
} else {
    print ">>> Downloading $tarball from GitHub...\n";
    system("wget -q $src_url") == 0
        or die "Failed to download $src_url\n";
}

# ---------------- EXTRACT ----------------
if (-d $src_dir) {
    print ">>> Removing old source directory $src_dir\n";
    system("rm -rf $src_dir");
}
system("tar -xzf $tarball") == 0 or die "Failed to extract $tarball\n";

# ---------------- BUILD ----------------
chdir($src_dir) or die "Cannot cd to $src_dir: $!\n";
print ">>> Configuring libevent with prefix = $prefix\n";

system("./configure --prefix=$prefix --disable-static --enable-shared") == 0
    or die "Configure failed!\n";

system("make clean");
system("make -j $nproc") == 0
    or die "Make failed!\n";

print ">>> Installing libevent...\n";
system("make install") == 0
    or die "Install failed!\n";

# ---------------- SYSTEM CONFIG ----------------
print ">>> Registering libevent in ld.so.conf.d\n";
open my $fh, ">", $ldconf_file
    or warn "Cannot write to $ldconf_file: $!\n";
print $fh "$prefix/lib\n" if $fh;
close $fh if $fh;
system("ldconfig");

# ---------------- VERIFY ----------------
print ">>> Verifying libevent installation...\n";
my $check = `ldconfig -p | grep libevent_core`;
if ($check =~ /libevent_core/) {
    print ">>> libevent successfully installed and detected:\n$check\n";
} else {
    warn "!!! libevent not detected in ldconfig output, please verify manually.\n";
}

# ---------------- FINISH ----------------
chdir($cwd);
print "====================================================\n";
print ">>> libevent $version installed successfully at $prefix\n";
print ">>> Add to your environment if needed:\n";
print "    export LD_LIBRARY_PATH=$prefix/lib:\$LD_LIBRARY_PATH\n";
print "====================================================\n";

#verification: libevent_core-2.1.so.7 (libc6,x86-64) => /opt/libevent/lib/libevent_core-2.1.so.7
print "\n>>> Current status for verification:\n";
system("ldconfig -p | grep libevent_core");
