#!/usr/bin/perl
use strict;
use warnings;
use Parallel::ForkManager;
use Cwd;

my $forkNo = 1;  # You can increase this to 5~10 for parallel node checking
my $pm = Parallel::ForkManager->new($forkNo);

# Define your node groups by IP base
my %nodes = (
    161 => [1..42],
    182 => [1..24],
    186 => [1..7],
    195 => [1..7],
    190 => [1..3],
    166 => [1..7]
);

# Determine cluster group based on server IP
my $ip = `/usr/sbin/ip a`;
$ip =~ /14\d\.1\d+\.\d+\.(\d+)/;
my $cluster = $1;
$cluster =~ s/^\s+|\s+$//;

my @allnodes = @{$nodes{$cluster}};
`/usr/bin/touch ~/scptest.dat`;

my @allgpu;
my @badgpu;
my @errgpu;
my @no_dkms;

for my $nodeid (@allnodes) {
    $pm->start and next;

    my $nodeindex = sprintf("%02d", $nodeid);
    my $nodename = "node$nodeindex";
    my $cmd = "/usr/bin/ssh $nodename";

    # Detect GPU via lspci
    my @gpu_check = `timeout 10 $cmd '/usr/sbin/lspci | grep -E "RTX 2080|RTX 3060|RTX 2060"'`;
    map { s/^\s+|\s+$//g } @gpu_check;

    if (@gpu_check) {
        print "\n\n$nodename has a GPU card:\n";
        push @allgpu, $nodename;

        # DKMS check
        my $dkms = `timeout 10 $cmd 'dkms status nvidia 2>&1'`;
        $dkms =~ s/^\s+|\s+$//g;
        print "dkms status nvidia: $dkms\n";

        if ($dkms =~ /command not found/i || $dkms eq '') {
            push @no_dkms, $nodename;
        }

        # nvidia-smi basic check
        print "nvidia-smi:\n";
        my @smi_check = `timeout 10 $cmd 'nvidia-smi -L 2>&1'`;
        my @smi_err = `timeout 10 $cmd 'nvidia-smi | grep ERR 2>&1'`;

        map { s/^\s+|\s+$//g } @smi_check;
        map { s/^\s+|\s+$//g } @smi_err;

        if (!@smi_check || join(" ", @smi_check) =~ /not found/i) {
            push @badgpu, $nodename;
        }

        if (@smi_err) {
            push @errgpu, $nodename;
        }

        print "nvidia-smi done\n";
    }

    $pm->finish;
}
$pm->wait_all_children;

# Write results to log
open(my $fh, '>', 'gpu_check.log') or die "Could not open log: $!";
print $fh "\n*** All GPU Nodes (Total: " . scalar(@allgpu) . ")\n";
print $fh "$_\n" for @allgpu;

print $fh "\n*** Bad GPUs (nvidia-smi not working): " . scalar(@badgpu) . "\n";
print $fh "$_\n" for @badgpu;

print $fh "\n*** ERR in nvidia-smi output: " . scalar(@errgpu) . "\n";
print $fh "$_\n" for @errgpu;

print $fh "\n*** DKMS missing or broken: " . scalar(@no_dkms) . "\n";
print $fh "$_\n" for @no_dkms;

close $fh;
print "\nCheck GPU status done. Summary:\n";
system("cat gpu_check.log");
