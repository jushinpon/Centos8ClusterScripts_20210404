#!/usr/bin/perl
# ===========================================================
# fix_slurm_pmix_env.pl
# Ensure PMIx/LibEvent environment variables exist
# in slurmctld.service (master) and slurmd.service (all nodes)
# Works when master also runs slurmd
# Author: Prof. Shin-Pon Ju (optimized by ChatGPT)
# ===========================================================

use strict;
use warnings;
use Expect;
use Parallel::ForkManager;
use Net::Ping;

my $expectT = 10;
my $nodefile = "./Nodes_IP.dat";
my $forkNo   = 8;

# --- Environment lines to enforce ---
my @env_lines = (
    'Environment="PATH=/opt/pmix/current/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin"',
    'Environment="LD_LIBRARY_PATH=/opt/pmix/current/lib:/opt/libevent/lib:/usr/local/lib:$LD_LIBRARY_PATH"'
);

# --- Helper color output ---
sub green  { "\e[32m$_[0]\e[0m" }
sub yellow { "\e[33m$_[0]\e[0m" }
sub red    { "\e[31m$_[0]\e[0m" }

# --- Load and filter node list ---
open my $fh, "<", $nodefile or die "Cannot open $nodefile: $!\n";
my @nodes = grep { $_ !~ /^\s*#/ && $_ !~ /^\s*$/ } <$fh>;
chomp @nodes;
close $fh;

print "Detected active nodes from $nodefile:\n";
print "  $_\n" for @nodes;
print "=====================================\n";

# -------------------------------------------------
# Subroutine to patch a given service file
# -------------------------------------------------
sub patch_service {
    my ($service_file, $service_name) = @_;
    if (! -f $service_file) {
        print red("✗ $service_name not found at $service_file\n");
        return;
    }
    my $need_patch = 0;
    foreach my $line (@env_lines) {
        my $found = `grep -q '$line' $service_file && echo FOUND || echo MISS`;
        chomp $found;
        $need_patch++ if $found eq 'MISS';
    }
    if ($need_patch) {
        print yellow("⚠ Patching $service_name ...\n");
        system("/bin/cp -f --remove-destination $service_file ${service_file}.bak");
        foreach my $line (@env_lines) {
            system("grep -q '$line' $service_file || sed -i '/^ExecStart/i $line' $service_file");
        }
        print green("✓ Patched $service_name\n");
    } else {
        print green("✓ $service_name already correct\n");
    }
}

# -------------------------------------------------
# Patch master node (slurmctld and slurmd if exists)
# -------------------------------------------------
print yellow("\n>>> Checking master node ...\n");
patch_service("/etc/systemd/system/slurmctld.service", "slurmctld.service");

if (-f "/etc/systemd/system/slurmd.service") {
    patch_service("/etc/systemd/system/slurmd.service", "slurmd.service (master)");
}

# Restart services on master
system("systemctl daemon-reload");
system("systemctl restart slurmctld 2>/dev/null");
system("systemctl restart slurmd 2>/dev/null");

print green("✓ Master node: services reloaded.\n");

# -------------------------------------------------
# Process compute nodes
# -------------------------------------------------
my $pm = Parallel::ForkManager->new($forkNo);
my $p  = Net::Ping->new("icmp");

foreach my $ip (@nodes) {
    $pm->start and next;

    if (!$p->ping($ip, 1)) {
        print red("✗ Node $ip not reachable, skipping.\n");
        $pm->finish;
    }

    print yellow("\n>>> Checking node $ip ...\n");

    my $exp = Expect->new;
    $exp = Expect->spawn("ssh -o StrictHostKeyChecking=no root\@$ip")
        or die "SSH to $ip failed.\n";

    # Check file existence
    $exp->send("[ -f /etc/systemd/system/slurmd.service ] && echo FILE_OK || echo FILE_FAIL\n");
    $exp->expect($expectT, '-re', 'FILE_(OK|FAIL)');
    my $status = $exp->match();
    if ($status =~ /FAIL/) {
        print red("✗ $ip: no slurmd.service found\n");
        $exp->send("exit\n");
        $exp->soft_close();
        $pm->finish;
        next;
    }

    # Check if patch needed
    my $need_patch = 0;
    foreach my $line (@env_lines) {
        $exp->send("grep -q '$line' /etc/systemd/system/slurmd.service && echo FOUND || echo MISS\n");
        $exp->expect($expectT, '-re', '(FOUND|MISS)');
        my $found = $exp->match();
        $need_patch++ if $found =~ /MISS/;
    }

    if ($need_patch) {
        print yellow("⚠ $ip: missing lines, patching...\n");
        $exp->send("/bin/cp -f --remove-destination /etc/systemd/system/slurmd.service /etc/systemd/system/slurmd.service.bak\n");
        foreach my $line (@env_lines) {
            $exp->send("grep -q '$line' /etc/systemd/system/slurmd.service || sed -i '/^ExecStart/i $line' /etc/systemd/system/slurmd.service\n");
        }
        $exp->send("systemctl daemon-reload && systemctl restart slurmd && echo RELOAD_OK || echo RELOAD_FAIL\n");
        $exp->expect($expectT, '-re', 'RELOAD_(OK|FAIL)');
        if ($exp->match() =~ /OK/) {
            print green("✓ $ip: slurmd restarted successfully\n");
        } else {
            print red("✗ $ip: slurmd reload failed\n");
        }
    } else {
        print green("✓ $ip: environment lines already correct\n");
    }

    $exp->send("exit\n");
    $exp->soft_close();
    $pm->finish;
}
$pm->wait_all_children;

print "\n=== ✅ All nodes (and master) verified/fixed ===\n";
print "Try:\n";
print "  srun --mpi=list\n";
print "  srun --mpi=pmix_v4 hostname\n";
print "===============================================\n";
