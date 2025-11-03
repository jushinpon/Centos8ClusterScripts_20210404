#!/usr/bin/perl
use strict;
use warnings;
use Cwd qw/getcwd abs_path/;

my $CurrentPath = getcwd(); #get perl code path

my $version      = "1.5.1"; # Desired version of VASPkit
my $download_page = "https://sourceforge.net/projects/vaspkit/files/Binaries/vaspkit.$version.linux.x64.tar.gz";
my $install_dir   = "/opt/vaspkit";

`rm -rf $install_dir` if -d $install_dir; # Clean up any existing installation directory

`mkdir /home/packages/vaspkit`;

chdir "/home/packages/vaspkit";
system("wget $download_page");
system("tar -xvzf vaspkit.$version.linux.x64.tar.gz");
system("mv vaspkit.$version $install_dir");
system("rm -f /usr/local/bin/vaspkit"); # Remove any existing symlink
system("ln -s $install_dir/bin/vaspkit /usr/local/bin/vaspkit"); # Create a symlink for easy access
print "VASPkit $version has been installed in $install_dir and symlinked to /usr/local/bin/vaspkit\n";