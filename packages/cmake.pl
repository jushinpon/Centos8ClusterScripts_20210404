use warnings;
use strict;
use Cwd; #Find Current Path
my $wgetORgit = "yes";
my $packageDir = "/home/packages";
if(!-e $packageDir){# if no /home/packages, make this folder	
	system("mkdir $packageDir");	
}

my $thread4make = `lscpu|grep "^CPU(s):" | sed 's/^CPU(s): *//g'`;
chomp $thread4make;
print "Total threads can be used for make: $thread4make\n";
system("dnf remove -y cmake");

my $URL = "https://github.com/Kitware/CMake.git";#url to download
my $Dir4download = "$packageDir/cmake_download"; #the directory we download Mpich
my $currentPath = getcwd(); #get perl code path

if($wgetORgit eq "yes"){
	system ("rm -rf $Dir4download");# remove the older directory first
	system("mkdir $Dir4download");# make a directory in current path
	chdir("$Dir4download");# cd to this dir for downloading the packages
	system("git clone $URL");	
	chdir("$currentPath");# cd to this dir
}

chdir("$Dir4download/CMake");# cd to this dir 
system("./bootstrap");
system("make -j $thread4make");
system("make install");
system("rm -f /usr/bin/cmake");
`ln -s /usr/local/bin/cmake /usr/bin/cmake`;
system("cmake --version");
