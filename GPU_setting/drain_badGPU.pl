use warnings;
use strict;
use Parallel::ForkManager;
#node06
#node03
#node04
#node05
my @badgpuNodes = qw(
node01
node24
node28
node40
node18
);

my $badgpu = join(",",@badgpuNodes);
chomp $badgpu;
system("scontrol update NodeName=$badgpu State=resume");
#system("scontrol update NodeName=$badgpu State=DRAIN Reason=\"Maintenance\"");
