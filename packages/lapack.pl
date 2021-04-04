=b
The following is compiling and linking for a fortran code using lapack lib:

gfortran -o cgorder ./cgorder.f -L'/opt/lapack' -llapack -lrefblas -ltmglib 

=cut

use warnings;
use strict;
use Cwd; #Find Current Path

my $wgetORgit = "yes";#yes or no
my $current_path = getcwd();# get the current path dir

if($wgetORgit eq "yes"){
	system("rm -rf /opt/lapack");
	chdir("/opt");
	system("git clone https://github.com/Reference-LAPACK/lapack.git");
	die "git clone lapack failed!!!\n" if($?);
}

chdir("/opt/lapack");
system("cp make.inc.example make.inc");
die "cp make.inc.example to make.inc failed!!!\n" if($?);
system ("make clean");
my $thread4make = `lscpu|grep "^CPU(s):" | sed 's/^CPU(s): *//g'`;
chomp $thread4make;
print "Total threads can be used for make: $thread4make\n";
system("make -j $thread4make");
#die "make lapack failed!!!\n" if($?);
print "*****Check whether lapack installation is ok\n\n";
sleep(3);
system("ls -al *.a");
print "\n\nIf you can see three .a files,";
print "lapack installation is done!!!\n Check /opt/lapack\n";
