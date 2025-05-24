#!/usr/bin/perl
# check the log after the line "=== Summary of Detected Problems ==="
use strict;
use warnings;
use POSIX qw(strftime);
# remove the old log file if exists
my $log_dir = "/root/";
my $log_prefix = "health_check_";
my @log_files = glob("$log_dir$log_prefix*.log");

foreach my $file (@log_files) {
    print "Removing old log file: $file\n";
    unlink $file or warn "Failed to remove $file: $!";
}
#die;

# Create log file
my $timestamp = strftime("%Y-%m-%d_%H-%M-%S", localtime);
my $logfile = "/root/health_check_$timestamp.log";
open my $LOG, '>', $logfile or die "Cannot open log file: $!";

# Initialize a summary of problems
my @problems;

sub log_and_run {
    my ($title, $cmd) = @_;
    print $LOG "\n=== $title ===\n";
    print $LOG "Command: $cmd\n\n";
    my @output = `$cmd 2>&1`;
    print $LOG @output;

    # Check for errors and add to summary
    foreach my $line (@output) {
        if ($line =~ /error|fail|critical|corrupt|not found|unavailable|denied|timeout|unmounted|unknown/i) {
            push @problems, "$title: $line";
        }
    }
}

# Network Diagnostics
log_and_run("Network Interfaces (ip addr)", "ip addr show");
log_and_run("DNS Configuration (/etc/resolv.conf)", "cat /etc/resolv.conf");
log_and_run("Default Route", "ip route");
log_and_run("Ping 8.8.8.8", "ping -c 4 8.8.8.8");
log_and_run("Ping google.com", "ping -c 4 google.com");
log_and_run("Traceroute to google.com", "traceroute google.com");

# System Logs
log_and_run("Recent Journal Errors", "journalctl -xe --no-pager -n 50");
log_and_run("Boot Journal Summary", "journalctl -b --no-pager");
log_and_run("NetworkManager Logs (Last 2 days)", "journalctl -u NetworkManager --since '2 days ago'");

# System Resources
log_and_run("Top Processes by Memory", "ps aux --sort=-%mem | head -n 10");
log_and_run("Top Processes by CPU", "ps aux --sort=-%cpu | head -n 10");
log_and_run("Memory Usage (free -h)", "free -h");
log_and_run("Disk Usage (df -h)", "df -h");
log_and_run("System Load (uptime)", "uptime");

# Disk Health
log_and_run("Disk I/O Stats (iostat)", "iostat -xz 1 3");

# Get list of all block devices
my @disks = `lsblk -d -o NAME | grep -v NAME | grep -v loop`;
chomp @disks;

foreach my $disk (@disks) {
    log_and_run("SMART Status ($disk)", "smartctl -a /dev/$disk");
}

# System Services
log_and_run("Failed Services", "systemctl list-units --failed");
log_and_run("Network Service Status", "systemctl status network");
log_and_run("Firewalld Status", "systemctl status firewalld");

# Hardware & Boot Errors
log_and_run("Kernel Errors (dmesg)", "dmesg -T | grep -iE 'error|fail|critical|corrupt'");

# Summary of Problems
print $LOG "\n=== Summary of Detected Problems ===\n";
if (@problems) {
    print $LOG "The following issues were detected:\n";
    print $LOG "$_\n" for @problems;
} else {
    print $LOG "No issues detected.\n";
}

close $LOG;
print "Health check complete. Output saved to $logfile\n";
