=b
https://blog.xuite.net/gk_128/my/191992709

=cut
use strict;
use warnings;
use Parallel::ForkManager;
my $part2check = "sdd";
my $bboutput = "/root/bb.log";
my $thread4make = `lscpu|grep "^CPU(s):" | sed 's/^CPU(s): *//g'`;
chomp $thread4make;
print "Total threads can be used for make: $thread4make\n";
my $forkNo = $thread4make;
my $pm = Parallel::ForkManager->new("$forkNo");
 
#system("badblocks -o /root/$part2check.bad /dev/$part2check"); 

open my $ss,"< $bboutput" or die "No bb.log to read"; 
my @temp_array=<$ss>;
my @all_bb=grep (($_!~m{^\s*$|^#}),@temp_array); # remove blank lines and comment lines
close $ss;
for (@all_bb){
	$_  =~ s/^\s+|\s+$//;
	chomp;
	print "bad blocks: $_\n";
}

for (@all_bb){	
	$pm->start and next;
	chomp;
	system("badblocks -f -w /dev/$part2check $_ $_");
	$pm->finish;
}
$pm->wait_all_children;
print "fix all bad blocks done!\n";
