#!/usr/bin/perl
use strict;
use warnings;
use Parallel::ForkManager;
use Cwd;

my $forkNo = 4;
my $pm = Parallel::ForkManager->new("$forkNo");

my %nodes = (
    161 => [1..42],
    182 => [1..24],
    186 => [1..7],
    195 => [1..7],
    190 => [1..3],
    166 => [1..7]
);

# Detect cluster group from IP
my $ip = `/usr/sbin/ip a`;    
$ip =~ /14\d\.1\d+\.\d+\.(\d+)/;
my $cluster = $1;
$cluster =~ s/^\s+|\s+$//;
my @allnodes = @{$nodes{$cluster}};

open(my $fh, '>', 'zombie_check.log') or die "❌ Could not open log: $!";

print $fh "===== Zombie Check (High-CPU Only) =====\n";
print $fh "Cluster $cluster Nodes: @allnodes\n\n";

for my $id (@allnodes) {
    $pm->start and next;

    my $nodeindex = sprintf("%02d", $id);
    my $nodename = "node$nodeindex";
    my $cmd = "/usr/bin/ssh $nodename";

    # Use awk instead of grep to prevent matching grep itself
    my @zombies = `$cmd "ps -eo pid,ppid,state,etime,pcpu,cmd | awk 'NR>1 && \\\$3 ~ /^Z/'"`;    

    my @high_cpu_zombies;

    foreach my $line (@zombies) {
        $line =~ s/^\s+|\s+$//g;
        my ($pid, $ppid, $stat, $etime, $cpu, $cmd) = split(/\s+/, $line, 6);
        next unless $cpu > 0.1;
        push @high_cpu_zombies, {
            pid => $pid, ppid => $ppid, stat => $stat,
            etime => $etime, cpu => $cpu, cmd => $cmd
        };
    }

    unless (@high_cpu_zombies) {
        $pm->finish;
    }

    # Write header only for affected nodes
    print $fh "=== $nodename ===\n";
    printf $fh "%-8s %-8s %-4s %-12s %-6s %s\n", "PID", "PPID", "STAT", "ELAPSED", "CPU%", "COMMAND";
    print $fh "-" x 80, "\n";

    foreach my $proc (@high_cpu_zombies) {
        printf $fh "%-8s %-8s %-4s %-12s %-6s %s\n",
            $proc->{pid}, $proc->{ppid}, $proc->{stat}, $proc->{etime}, $proc->{cpu}, $proc->{cmd};

        print $fh "  🔥 High-CPU zombie using $proc->{cpu}%\n";

        # Dump stack trace
        my @stack = `$cmd "cat /proc/$proc->{pid}/stack 2>/dev/null"`;
        if (@stack) {
            print $fh "  📜 Stack trace:\n";
            foreach (@stack) { print $fh "    $_"; }
        } else {
            print $fh "  🚫 Stack trace unavailable (zombie may have exited).\n";
        }

        if ($proc->{ppid} == 1) {
            print $fh "  ⚠️  Cannot clean: parent is init (PID 1).\n";
        } else {
            print $fh "  💀 Consider killing parent PID $proc->{ppid}.\n";
        }
        print $fh "\n";
    }

    $pm->finish;
}

$pm->wait_all_children;
close $fh;
print "✅ Zombie check complete. See zombie_check.log for high-CPU zombies.\n";
system("cat zombie_check.log");
