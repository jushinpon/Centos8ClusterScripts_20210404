#!/usr/bin/perl

use strict;
use warnings;
use POSIX qw(strftime);

# === SLURM Master Node Recovery ===
my $slurmctld_spool = "/var/spool/slurmctld";
my $backup_prefix = strftime("%Y%m%d_%H%M%S", localtime);
my $backup_file = "/root/slurmctld_backup_$backup_prefix.tar.gz";

print "[MASTER] Stopping slurmctld...\n";
system("systemctl stop slurmctld") == 0 or die "Failed to stop slurmctld\n";

print "[MASTER] Backing up $slurmctld_spool to $backup_file...\n";
system("tar czf $backup_file $slurmctld_spool") == 0 or die "Failed to backup slurmctld spool\n";

print "[MASTER] Cleaning $slurmctld_spool...\n";
system("rm -rf $slurmctld_spool/*") == 0 or die "Failed to clean slurmctld spool\n";

print "[MASTER] Starting slurmctld...\n";
system("systemctl start slurmctld") == 0 or die "Failed to start slurmctld\n";

# === Clear held/requeued failed jobs ===
print "[MASTER] Cancelling held/requeued failed jobs...\n";
system("squeue | grep 'launch failed requeued held' | awk '{print \\\$1}' | xargs scancel");

# === Resume all nodes ===
print "[MASTER] Resuming all nodes...\n";
system("scontrol update NodeName=ALL State=RESUME") == 0 or warn "Failed to resume nodes\n";

# === Define cluster-wise nodes ===
my %nodes = (
    161 => [1..42],
    182 => [1..24],
    186 => [1..7],
    195 => [1..7],
    190 => [1..3],
);

my %badnodes = (
    161 => [100],
    182 => [100],
    186 => [100],
    195 => [100],
    190 => [100],
);

my $ip = `/usr/sbin/ip a`;
$ip =~ /14\d\.1\d+\.\d+\.(\d+)/;
my $cluster = $1;
$cluster =~ s/^\s+|\s+\$//;

my @allnodes = @{$nodes{$cluster}};
my @bad = @{$badnodes{$cluster}};

my @nodes;
foreach my $n (@allnodes) {
    push @nodes, $n unless grep { $_ == $n } @bad;
}

foreach my $n (@nodes) {
    my $nodename = sprintf("node%02d", $n);
    print "[NODE] Recovering $nodename...\n";
    system("ssh $nodename 'systemctl stop slurmd'") == 0 or warn "Failed to stop slurmd on $nodename\n";
    system("ssh $nodename 'rm -rf /var/spool/slurmd/*'") == 0 or warn "Failed to clean slurmd spool on $nodename\n";
    system("ssh $nodename 'systemctl start slurmd'") == 0 or warn "Failed to start slurmd on $nodename\n";
    system("scontrol update NodeName=$nodename State=RESUME") == 0 or warn "Failed to resume $nodename\n";
}

print "[DONE] SLURM cluster full recovery complete.\n";
