#!/usr/bin/perl
# ==============================================================
#  Auto installer for PMIx 4.2.9 (using libevent from /opt/libevent)
#  Author: Prof. Shin-Pon Ju | Refined by ChatGPT (2025)
#  Version: 2025-10-07
# ==============================================================
use strict;
use warnings;
use Cwd;

# ---------------- CONFIG ----------------
my $version      = "4.2.9";
my $prefix       = "/opt/pmix/$version";
my $base_dir     = "/opt/pmix";
my $package_dir  = "/home/packages";
my $build_dir    = "$package_dir/pmix_build";
my $tarball      = "pmix-$version.tar.gz";
my $src_url      = "https://github.com/openpmix/openpmix/releases/download/v$version/$tarball";
my $src_dir      = "$build_dir/pmix-$version";
my $ldconf_file  = "/etc/ld.so.conf.d/pmix.conf";

my $libevent_dir = "/opt/libevent";  # must already exist

# ---------------- ENVIRONMENT CHECK ----------------
print ">>> Checking environment...\n";
if (! -d $libevent_dir) {
    die "ERROR: libevent directory $libevent_dir not found! Install libevent first.\n";
}

my $libevent_core = `ldconfig -p | grep libevent_core-2.1.so.7`;
if ($libevent_core !~ /libevent_core-2.1.so.7/) {
    die "ERROR: libevent_core-2.1.so.7 not found in ldconfig. Please verify libevent installation.\n";
}

print ">>> libevent found at /opt/libevent/lib\n";

# ---------------- PREPARE ENV ----------------
system("mkdir -p $package_dir $build_dir $base_dir");
my $cwd = getcwd();

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
print ">>> Configuring PMIx $version with libevent at $libevent_dir\n";

my $config_cmd = "./configure --prefix=$prefix --with-libevent=$libevent_dir";
system($config_cmd) == 0 or die "Configure failed!\n";

system("make clean");
system("make -j $nproc") == 0 or die "Make failed!\n";

print ">>> Installing PMIx...\n";
system("make install") == 0 or die "Install failed!\n";

# ---------------- SYMLINK ----------------
print ">>> Setting /opt/pmix/current symlink...\n";
if (-e "$base_dir/current") {
    system("rm -f $base_dir/current");
}
system("ln -sfn $prefix $base_dir/current");

# ---------------- SYSTEM CONFIG ----------------
print ">>> Registering PMIx in ld.so.conf.d\n";
open my $fh, ">", $ldconf_file
    or warn "Cannot write to $ldconf_file: $!\n";
print $fh "$prefix/lib\n" if $fh;
close $fh if $fh;
system("ldconfig");

# ---------------- VERIFY ----------------
print ">>> Verifying PMIx linkage...\n";
my $check = `ldd $prefix/lib/libpmix.so | grep event_core`;
if ($check =~ /libevent_core/) {
    print ">>> PMIx correctly linked to libevent:\n$check\n";
} else {
    warn "!!! PMIx may not be linked to libevent correctly. Please verify manually.\n";
}

# ---------------- FINISH ----------------
chdir($cwd);
print "====================================================\n";
print ">>> PMIx $version installed successfully at $prefix\n";
print ">>> Symlink: /opt/pmix/current\n";
print ">>> Add to your environment if needed:\n";
print "    export PATH=/opt/pmix/current/bin:\$PATH\n";
print "    export LD_LIBRARY_PATH=/opt/pmix/current/lib:\$LD_LIBRARY_PATH\n";
print "====================================================\n";
