#!/usr/bin/perl
use strict;
use warnings;
use Net::Ping;
use POSIX qw(strftime);

# ================================================================
# SLURM AUTOHEAL v5
# Comprehensive self-healing tool for Slurm clusters
# - Fixes network congestion and socket storms
# - Cleans zombie jobs and uncontrolled processes
# - Tunes kernel TCP parameters
# - Repairs slurmd, chronyd, and network interfaces
# ================================================================

# ------------- CONFIGURATION -----------------------------------
my $master = `hostname`; chomp($master);
my @slurm_ports = (6817, 6818, 6819);
my $logfile = "/root/slurm_autoheal_v5.log";
my $max_job_hours = 4;   # Cancel jobs older than this many hours
# ---------------------------------------------------------------

# Auto-detect all compute nodes dynamically
my @nodes;
my $nodelist = `scontrol show nodes | grep -E "^NodeName=" 2>/dev/null`;
foreach my $line (split /\n/, $nodelist) {
    if ($line =~ /NodeName=([\w\.\-]+)/) {
        push @nodes, $1;
    }
}

# If detection fails, fallback to default pattern (node01–node10)
if (!@nodes) {
    print "⚠️  Unable to detect nodes from Slurm — using default node01–node10.\n";
    @nodes = map { sprintf("node%02d", $_) } (1..10);
}

open my $LOG, ">>", $logfile or die "Cannot open $logfile: $!";
my $time = strftime "%Y-%m-%d %H:%M:%S", localtime;
print $LOG "\n===== SLURM AUTOHEAL v5 @ $time =====\n";

print "\n===== SLURM AUTOHEAL v5 START =====\n";

# ------------------ MAIN WORKFLOW ------------------------------
clean_old_jobs();                 # kill uncontrolled or old jobs
check_master_services();          # verify controller daemons
check_ntp_sync($master);          # sync time

foreach my $node (@nodes) {
    print "\n--- Checking $node ---\n";
    logit("\n[$node]");
    next unless check_network($node);
    next unless check_ssh($node);
    check_ntp_sync($node);
    check_and_repair_slurmd($node);
    detect_heavy_jobs($node);
}

fix_network_congestion();         # fix switch-saturating socket storms

print "\n=== Resuming all DOWN nodes ===\n";
system("scontrol update nodename=ALL state=resume >/dev/null 2>&1");

print "\n=== Final cluster health ===\n";
system("sinfo -N -l");

print $LOG "===== END =====\n";
close $LOG;
print "===== AUTOHEAL FINISHED =====\n";

# ================================================================
#                        SUBROUTINES
# ================================================================

sub logit { print $LOG shift, "\n"; }

# ---------------------------------------------------------------
# 1️⃣ CLEAN OLD JOBS & ORPHANS
# ---------------------------------------------------------------
sub clean_old_jobs {
    print "\n=== Cleaning old or uncontrolled Slurm jobs ===\n";
    my $jobs = `squeue -h -o "%i %t %M %N %u"`;
    my @lines = split /\n/, $jobs;
    foreach my $line (@lines) {
        my ($jobid, $state, $runtime, $nodes, $user) = split /\s+/, $line, 5;
        my ($h,$m,$s) = split /:/, $runtime;
        my $hours = $h + ($m||0)/60 + ($s||0)/3600;
        my $node_state = `sinfo -N -n $nodes -h -o "%T"`; chomp $node_state;

        if ($hours > $max_job_hours || $node_state =~ /DOWN|DRAIN|FAIL|REBOOT/) {
            print "⚠️ Cancelling job $jobid ($state, ${hours}h on $nodes)\n";
            system("scancel $jobid");
            logit("Cancelled old/uncontrolled job $jobid ($state $runtime $nodes)");
        }
    }

    print "\n=== Scanning for orphaned DeepMD/QE processes ===\n";
    my $orphans = `ps -eo pid,etime,comm,user | grep -E "deepmd|pw.x|lmp|mpirun" | grep -v grep`;
    if ($orphans) {
        foreach my $ln (split /\n/, $orphans) {
            if ($ln =~ /^\s*(\d+)/) {
                my $pid = $1;
                print "💀 Killing orphan PID=$pid\n";
                system("kill -9 $pid");
                logit("Killed orphan PID=$pid ($ln)");
            }
        }
    } else { print "✅ No orphan DeepMD/QE processes found\n"; }
}

# ---------------------------------------------------------------
# 2️⃣ MASTER SERVICES
# ---------------------------------------------------------------
sub check_master_services {
    print "\n=== Checking master services ===\n";
    foreach my $svc (qw(slurmctld slurmdbd)) {
        my $st = `systemctl is-active $svc 2>/dev/null`; chomp $st;
        if ($st ne "active") {
            print "❌ $svc not active, restarting...\n";
            system("systemctl restart $svc");
            sleep 2;
            my $new = `systemctl is-active $svc 2>/dev/null`; chomp $new;
            print ($new eq "active" ? "✅ $svc restarted\n" : "⚠️ restart failed\n");
            logit("$svc restarted ($new)");
        } else { print "✅ $svc running\n"; }
    }
}

# ---------------------------------------------------------------
# 3️⃣ NETWORK & NTP
# ---------------------------------------------------------------
sub check_network {
    my ($node)=@_;
    my $p=Net::Ping->new("icmp",1);
    my $ok=$p->ping($node);
    $p->close();
    if(!$ok){ print "❌ $node unreachable\n"; logit("$node unreachable"); return 0; }
    print "✅ ping ok\n";
    foreach my $port (@slurm_ports){
        my $r=system("nc -z -w1 $node $port >/dev/null 2>&1");
        if($r!=0){
            print "⚠️ $node port $port closed → restarting slurmd\n";
            system("ssh $node 'systemctl restart slurmd' >/dev/null 2>&1");
            logit("$node port $port closed, restarted slurmd");
        }
    }
    return 1;
}

sub check_ssh {
    my ($node)=@_;
    my $r=system("ssh -o BatchMode=yes -o ConnectTimeout=3 $node 'hostname' >/dev/null 2>&1");
    if($r!=0){ print "❌ SSH failed\n"; logit("$node SSH failed"); return 0; }
    print "✅ SSH ok\n"; return 1;
}

sub check_ntp_sync {
    my ($target)=@_;
    my $cmd=$target eq $master?"timedatectl":"ssh $target 'timedatectl'";
    my $out=`$cmd 2>/dev/null`;
    if($out!~/synchronized:\s*yes/i){
        print "⚠️ $target not synced → restarting chronyd\n";
        my $fix=$target eq $master?"systemctl restart chronyd":"ssh $target 'systemctl restart chronyd'";
        system($fix);
        logit("$target chronyd restarted");
    } else { print "✅ $target time synced\n"; }
}

# ---------------------------------------------------------------
# 4️⃣ SLURMD CHECK & REPAIR
# ---------------------------------------------------------------
sub check_and_repair_slurmd {
    my ($node)=@_;
    my $st=`ssh -o ConnectTimeout=3 $node 'systemctl is-active slurmd' 2>/dev/null`;
    chomp $st;
    if($st eq "active"){ print "✅ slurmd running\n"; return; }
    print "❌ slurmd down → cleaning spool & restarting...\n";
    system("ssh $node 'systemctl stop slurmd; rm -rf /var/spool/slurm/d*; systemctl start slurmd'");
    sleep 2;
    my $re=`ssh $node 'systemctl is-active slurmd' 2>/dev/null`; chomp $re;
    if($re eq "active"){ print "✅ slurmd recovered\n"; logit("$node slurmd recovered"); }
    else { print "⚠️ slurmd restart failed → rebooting node\n"; system("ssh $node 'reboot' >/dev/null 2>&1 &"); logit("$node rebooted"); }
}

# ---------------------------------------------------------------
# 5️⃣ DETECT HEAVY JOBS
# ---------------------------------------------------------------
sub detect_heavy_jobs {
    my ($node)=@_;
    my $ps=`ssh $node "ps -eo pid,pcpu,pmem,comm --sort=-pcpu | head -n 10" 2>/dev/null`;
    foreach my $ln (split /\n/, $ps){
        if($ln =~ /\b(deepmd|python|pw\.x|lmp|mpirun)\b/ && $ln =~ /(\d+\.\d+)/){
            my $cpu=$1;
            if($cpu>400){
                if($ln =~ /^\s*(\d+)/){
                    my $pid=$1;
                    print "⚠️  High-CPU runaway [$ln] → killing\n";
                    system("ssh $node 'kill -9 $pid' >/dev/null 2>&1");
                    logit("$node killed PID $pid ($ln)");
                }
            }
        }
    }
}

# ---------------------------------------------------------------
# 6️⃣ NETWORK CONGESTION PROTECTION
# ---------------------------------------------------------------
sub fix_network_congestion {
    print "\n=== Applying network congestion protection ===\n";
    my $sysctl_conf = <<'EOF';
net.core.somaxconn = 4096
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 10
net.ipv4.ip_local_port_range = 1024 65000
net.ipv4.tcp_max_syn_backlog = 4096
EOF

    foreach my $node (@nodes) {
        print "→ Tuning TCP stack on $node ...\n";
        open my $fh, '>', "/tmp/sysctl_net.conf";
        print $fh $sysctl_conf;
        close $fh;
        system("scp -q /tmp/sysctl_net.conf $node:/etc/sysctl.d/99-slurm-net.conf");
        system("ssh $node 'sysctl -p /etc/sysctl.d/99-slurm-net.conf >/dev/null 2>&1'");
    }

    foreach my $node (@nodes) {
        print "→ Checking sockets on $node ...\n";
        my $sock = `ssh $node 'ss -s | grep estab' 2>/dev/null`;
        if ($sock =~ /estab:\s*(\d+)/) {
            my $num = $1;
            if ($num > 20000) {
                print "⚠️  $node has $num sockets → killing socket-heavy processes\n";
                system("ssh $node 'ps -eo pid,comm | grep -E \"deepmd|pw.x|mpirun|python\" | awk \"{print \\\$1}\" | xargs -r kill -9'");
            }
        }
    }

    foreach my $node (@nodes) {
        my $eth = `ssh $node 'ip route show default | awk \"{print \\\$5}\"' 2>/dev/null`;
        chomp($eth);
        next unless $eth;
        my $drops = `ssh $node 'ethtool -S $eth | grep -E \"rx_dropped|tx_dropped\" | awk \"{s+=\\\$2} END{print s}\"' 2>/dev/null`;
        chomp($drops);
        if ($drops && $drops > 10000) {
            print "⚠️  High packet drop on $node:$eth ($drops) → restarting interface\n";
            system("ssh $node 'ip link set $eth down; sleep 1; ip link set $eth up'");
            logit("$node $eth restarted due to packet drops ($drops)");
        }
    }

    print "✅ Network congestion protection applied.\n";
}
