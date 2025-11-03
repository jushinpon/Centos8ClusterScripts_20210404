#!/usr/bin/perl
use strict;
use warnings;

my $what2do = "shutdown -h now";

# Submit AT jobs for compute nodes
system("ssh node01 \"echo '$what2do' | at 06:50 2025-8-10\"");
system("ssh node02 \"echo '$what2do' | at 06:50 2025-8-10\"");
system("ssh node03 \"echo '$what2do' | at 06:50 2025-8-10\"");
system("ssh node04 \"echo '$what2do' | at 06:50 2025-8-10\"");
# Submit AT job for master node itself
system("echo '$what2do' | at 06:45 2025-8-10");
system("echo 'scancel -u *' | at 06:35 2025-8-10");

print "\n✅ Shutdown at jobs scheduled on compute nodes and master node.\n";
