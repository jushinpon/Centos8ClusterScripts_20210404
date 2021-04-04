use strict;
use warnings;

my @allPackages = ("00pack_mpich.pl", "00pack_lammps.pl","00pack_qe.pl");

for (@allPackages){
	print "****Execute Perl script: $_ \n";
	system("perl $_");
	sleep(1);
}
