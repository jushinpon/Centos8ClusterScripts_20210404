#!/usr/bin/perl
use strict;
use warnings;
use Cwd;

# Stop Slurm services
system("systemctl stop slurmd.service");
system("systemctl stop slurmctld.service");

# Disable Slurm services
system("systemctl disable slurmd.service");
system("systemctl disable slurmctld.service");

# Remove Slurm packages installed via DNF
system("dnf remove -y slurm*");

# Define paths to be removed
my @paths_to_remove = (
    "/root/slurm", 
    #"/home/packages/slurm_download", 
    "/etc/slurm", 
    "/etc/systemd/system/slurmd.service", 
    "/etc/systemd/system/slurmctld.service",
    "/usr/local/etc/slurm.conf",
    "/var/log/slurmctld.log",
    "/var/log/slurm_jobacct.log",
    "/var/log/slurm_jobcomp.log",
    "/var/log/slurmd.log",
    "/var/run/slurmd.pid",
    "/var/run/slurmctld.pid",
    "/var/spool/slurmd",
    "/var/spool/slurmctld",
    "/usr/local/sbin/slurm*",
    "/usr/local/bin/srun",
    "/usr/local/bin/sbatch",
    "/usr/local/bin/scancel",
    "/usr/local/bin/sacct",
    "/usr/local/bin/scontrol",
    "/usr/local/bin/sinfo",
    "/usr/local/bin/squeue",
    "/usr/local/bin/sacctmgr",
    "/usr/local/lib/slurm",
    "/usr/local/lib64/slurm",
    "/usr/lib64/slurm",
    "/usr/lib/slurm",
    "/usr/share/man/man1/srun.1.gz",
    "/usr/share/man/man1/sbatch.1.gz",
    "/usr/share/man/man1/scancel.1.gz",
    "/usr/share/man/man1/sacct.1.gz",
    "/usr/share/man/man1/scontrol.1.gz",
    "/usr/share/man/man1/sinfo.1.gz",
    "/usr/share/man/man1/squeue.1.gz",
    "/usr/share/man/man1/sacctmgr.1.gz"
);

# Remove all directories and files
foreach my $path (@paths_to_remove) {
    system("rm -rf $path");
}

# Reload systemd daemon to reflect service removal
system("systemctl daemon-reload");

print "Slurm and all related files have been completely removed.\n";
