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

# Print header
print "\nChecking AVX2 support for nodes in cluster: $cluster\n";
print "---------------------------------------------------\n";
print "Node Name    | AVX Support\n";
print "------------ | --------------------------------\n";

# Test connectivity and check AVX flags
for my $node (@allnodes) {
    my $nodeindex = sprintf("%02d", $node);
    my $nodename = "node$nodeindex";

    # Test SSH connectivity and check for AVX flags
    my $avx_output = `ssh -o ConnectTimeout=5 root\@$nodename "grep -m1 'flags' /proc/cpuinfo | grep -o 'avx[^ ]*'"`;

    # Verify SSH success
    if ($?) {
        printf "%-12s | \033[31mSSH FAILED\033[0m\n", $nodename;
    } else {
        chomp $avx_output;
        if ($avx_output =~ /\bavx2\b/) {
            printf "%-12s | \033[32mAVX2 Supported\033[0m (%s)\n", $nodename, $avx_output;
        } elsif ($avx_output =~ /\bavx\b/) {
            printf "%-12s | \033[33mOnly AVX1 Supported\033[0m (%s)\n", $nodename, $avx_output;
        } else {
            printf "%-12s | \033[31mNo AVX Support Detected\033[0m\n", $nodename;
        }
    }
}
