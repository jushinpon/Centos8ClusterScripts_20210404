#!/usr/bin/perl

use strict;
use warnings;

# Cluster and node mapping
my %nodes = (
    161 => [1..42],
    182 => [6, 20..24],
    186 => [1..10],
    190 => [1..3]
);

# Determine cluster based on IP
my $ip = `/usr/sbin/ip a`;
$ip =~ /140\.117\.\d+\.(\d+)/;
my $cluster = $1;
$cluster =~ s/^\s+|\s+$//;

# Prepare nodes list based on cluster
my @allnodes = @{$nodes{$cluster}};

# Test connectivity and check AVX flags
for my $node (@allnodes) {
    my $nodeindex = sprintf("%02d", $node);
    my $nodename = "node$nodeindex";
    print "Checking $nodename status\n";

    # Test SSH connectivity with a simple command and check for AVX flags
    my $avx_output = `ssh -o ConnectTimeout=5 root\@$nodename "grep -m1 'flags' /proc/cpuinfo | grep -o 'avx[^ ]*'"`;

    # Verify SSH success and output AVX details
    if ($?) {
        print "SSH connection to $nodename failed.\n";
    } else {
        chomp $avx_output;
        print "$nodename supports: \n$avx_output\n";
    }
}
