#!/usr/bin/perl
use strict;
use warnings;

# Define log and SLURM directories (Modify if necessary)
my $slurmctld_log = "/var/log/slurmctld.log";
my $slurm_job_dir = "/var/spool/slurmctld";
my $slurm_state_save = "/var/lib/slurm";

# Function to get running jobs
sub get_running_jobs {
    my %jobs;
    open(my $fh, "-|", "squeue -h -o '%i %u %T'") or die "Failed to execute squeue: $!";
    while (<$fh>) {
        chomp;
        my ($jobid, $user, $state) = split(/\s+/, $_, 3);
        $jobs{$jobid} = { user => $user, state => $state };
    }
    close($fh);
    return %jobs;
}

# Function to find duplicate job IDs
sub find_duplicate_jobs {
    my %jobs = @_;
    my %seen;
    my @duplicates;
    foreach my $jobid (keys %jobs) {
        if ($seen{$jobid}) {
            push @duplicates, $jobid;
        } else {
            $seen{$jobid} = 1;
        }
    }
    return @duplicates;
}

# Function to cancel jobs
sub cancel_jobs {
    my @jobs = @_;
    foreach my $job (@jobs) {
        print "Cancelling job: $job\n";
        system("scancel $job");
    }
}

# Function to clean SLURM job cache files
sub clean_job_cache {
    print "Cleaning SLURM job cache...\n";
    system("rm -f $slurm_job_dir/*.job");
    system("rm -f $slurm_job_dir/*.batch");
    system("rm -rf $slurm_state_save/job_state");
    system("truncate -s 0 $slurmctld_log");
}

# Function to force SLURM database cleanup
sub force_db_cleanup {
    print "Forcing SLURM job database cleanup...\n";
    system("sacctmgr -i purge job");
}

# Function to restart SLURM services
sub restart_slurm {
    print "Restarting SLURM services...\n";
    system("systemctl restart slurmctld");
    system("systemctl restart slurmd");
}

# Function to reboot affected nodes
sub reboot_nodes {
    my @nodes = @_;
    foreach my $node (@nodes) {
        print "Rebooting node: $node\n";
        system("scontrol reboot NodeName=$node Reason='Recovering from duplicate jobid error'");
    }
}

# Function to get affected nodes
sub get_affected_nodes {
    my @nodes;
    open(my $fh, "-|", "squeue -h -o '%N %T' | grep 'PD'") or die "Failed to execute squeue: $!";
    while (<$fh>) {
        chomp;
        my ($node, $state) = split(/\s+/, $_, 2);
        push @nodes, $node if $state =~ /(DOWN|DRAINED)/;
    }
    close($fh);
    return @nodes;
}

# --- Main Execution ---
my %jobs = get_running_jobs();
my @duplicates = find_duplicate_jobs(%jobs);

if (@duplicates) {
    print "Found duplicate job IDs: @duplicates\n";
    cancel_jobs(@duplicates);
}

# Clean up SLURM job cache
clean_job_cache();

# Force job database cleanup
force_db_cleanup();

# Restart SLURM services
restart_slurm();

# Check if nodes need rebooting
my @nodes_to_reboot = get_affected_nodes();
if (@nodes_to_reboot) {
    print "Nodes to reboot: @nodes_to_reboot\n";
    reboot_nodes(@nodes_to_reboot);
}

print "SLURM recovery process completed!\n";
