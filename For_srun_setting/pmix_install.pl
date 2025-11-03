#!/usr/bin/perl
#cpan JSON.pm
#cpan LWP::Simple
use strict;
use warnings;
use Cwd;
use JSON;
use LWP::Simple;
`cpan JSON` if ! eval { require JSON; };
`cpan LWP::Simple` if ! eval { require LWP::Simple; };
# ========================================
# Auto installer for latest PMIx release
# Installs to /opt/pmix/<version> and symlinks /opt/pmix/current
# Author: Prof. Shin-Pon Ju (modified by ChatGPT)
# ========================================

# --- user config ---
my $install_dir = "/opt/pmix";   # base install prefix
my $package_dir = "/home/packages";
my $build_dir   = "$package_dir/pmix_build";

# --- detect cores for make ---
my $nproc = `nproc`;
chomp $nproc;
$nproc = 4 if !$nproc; # fallback
print ">>> Detected $nproc build threads available\n";

# --- query GitHub for latest PMIx release ---
print ">>> Fetching latest PMIx release from GitHub...\n";
my $json_url = "https://api.github.com/repos/openpmix/openpmix/releases/latest";
my $json = get($json_url) or die "Could not fetch $json_url\n";
my $release = decode_json($json);
my $pmix_version = $release->{"tag_name"};  # e.g. "v4.2.9"
$pmix_version =~ s/^v//;                   # remove leading 'v'
print ">>> Latest PMIx version: $pmix_version\n";

# --- tarball URL ---
my $tarball = "pmix-$pmix_version.tar.gz";
my $url = "https://github.com/openpmix/openpmix/releases/download/v$pmix_version/$tarball";
my $src_dir = "$build_dir/pmix-$pmix_version";
my $prefix  = "$install_dir/$pmix_version";

# --- prepare dirs ---
my $cwd = getcwd();
system("mkdir -p $package_dir $build_dir $install_dir");

# --- download tarball ---
chdir($build_dir) or die "Cannot cd to $build_dir: $!\n";
if (! -e $tarball) {
    print ">>> Downloading $tarball...\n";
    system("wget $url") == 0 or die "Download failed: $!\n";
} else {
    print ">>> Found existing tarball $tarball, skipping download.\n";
}

# --- extract ---
if (-d $src_dir) {
    print ">>> Removing old source dir $src_dir\n";
    system("rm -rf $src_dir");
}
system("tar -xzf $tarball") == 0 or die "Extraction failed: $!\n";

# --- build ---
chdir($src_dir) or die "Cannot cd to $src_dir: $!\n";
print ">>> Configuring with prefix $prefix\n";
system("./configure --prefix=$prefix --with-libevent=/opt/libevent") == 0
    or die "Configure failed: $!\n";

system("make clean");
system("make -j $nproc") == 0 or die "Make failed: $!\n";
system("make install") == 0 or die "Make install failed: $!\n";

# --- symlink for convenience ---
if (-e "$install_dir/current") {
    system("rm -f $install_dir/current");
}
system("ln -sfn $prefix $install_dir/current");

# --- update ldconfig ---
open my $fh, ">>", "/etc/ld.so.conf.d/pmix.conf"
    or warn "Could not open /etc/ld.so.conf.d/pmix.conf: $!";
print $fh "$prefix/lib\n" if $fh;
close $fh if $fh;
system("ldconfig");

print ">>> PMIx $pmix_version installed successfully under $prefix\n";
print ">>> Use the symlink /opt/pmix/current for builds.\n";
print ">>> Add to your shell:\n";
print "    export PATH=/opt/pmix/current/bin:\$PATH\n";
print "    export LD_LIBRARY_PATH=/opt/pmix/current/lib:\$LD_LIBRARY_PATH\n";

chdir($cwd);
