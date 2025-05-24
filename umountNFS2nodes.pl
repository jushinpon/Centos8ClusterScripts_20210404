#!/usr/bin/perl
use strict;
use warnings;

# Step 1: Retrieve the list of failed mount units properly
my @failed_mounts = `systemctl list-units --type mount --state=failed --no-pager | awk '{print \$1}'`;
chomp(@failed_mounts);  # Clean up newlines

# Step 2: Ensure unit names are correctly escaped
my @escaped_mounts;
foreach my $mount (@failed_mounts) {
    next if $mount eq "UNIT" || $mount eq "LOAD";  # Ignore headers
    my $escaped_mount = `systemd-escape --suffix=mount "$mount"`;
    chomp($escaped_mount);
    push @escaped_mounts, $escaped_mount;
}

# Step 3: Stop, disable, and mask each failed mount unit
foreach my $mount (@escaped_mounts) {
    print "Disabling and masking $mount...\n";
    system("sudo systemctl stop $mount");
    system("sudo systemctl disable $mount");
    system("sudo systemctl mask $mount");
}

# Step 4: Remove lingering unit files
print "Removing lingering mount unit files...\n";
foreach my $mount (@escaped_mounts) {
    system("sudo rm -f /etc/systemd/system/$mount");
}

# Step 5: Reload systemd daemon
print "Reloading systemd daemon...\n";
system("sudo systemctl daemon-reexec");

# Step 6: Reset failed systemd units
print "Resetting failed systemd units...\n";
system("sudo systemctl reset-failed");

# Step 7: Verify that mount units are fully removed
print "Checking remaining failed mount units...\n";
system("systemctl list-units --type mount --state=failed --no-pager");

print "Completed mount unit cleanup.\n";