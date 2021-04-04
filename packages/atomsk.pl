=b
The script help you install atomsk.
You need to install lapack in advance.

https://atomsk.univ-lille.fr/index.php 

=cut

use warnings;
use strict;
use Cwd; #Find Current Path

my $packageDir = "/home/packages";
if(!-e $packageDir){# if no /home/packages, make this folder	
	system("mkdir $packageDir");	
}

my $wgetORgit = "yes";#yes or no
my $current_path = getcwd();# get the current path dir
my $URL = "https://github.com/pierrehirel/atomsk/";#url to download
my $Dir4download = "$packageDir/atomsk_download"; #the directory we download Mpich

if($wgetORgit eq "yes"){
	system("rm -rf $Dir4download");
	system("mkdir $Dir4download");
	chdir("$Dir4download");
	system("git clone $URL");
	die "git clone atomsk failed!!!\n" if($?);
	chdir("$Dir4download/atomsk/src");
	`sed -i 's:LAPACK=.*:LAPACK=-L'/opt/lapack' -llapack -lrefblas -ltmglib:' "Makefile"`;
	chdir("$current_path");

}

chdir("$Dir4download/atomsk/src");
system("make clean");
system("make -j 8 atomsk");
system("make install");
