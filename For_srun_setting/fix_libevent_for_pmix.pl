#!/usr/bin/perl
use strict;
use warnings;
use Expect;
use Parallel::ForkManager;

# ======================================================
# Fix libevent linkage for PMIx across all cluster nodes
# Author: Prof. Shin-Pon Ju (modified by ChatGPT)
# ======================================================

my $expectT = 10;
my $NodesFile = "./Nodes_IP.dat";

# === read node IPs ===
open my $fh, "<", $NodesFile or die "Cannot open $NodesFile: $!\n";
my @ips = grep { $_ !~ /^\s*#/ && $_ !~ /^\s*$/ } <$fh>;
close $fh;
chomp @ips;

print "\n=== Nodes to process ===\n";
print join("\n", @ips), "\n\n";

my $pm = Parallel::ForkManager->new(scalar @ips + 1);

foreach my $ip (@ips) {
    $pm->start and next;

    print ">>> [$ip] Checking /opt/libevent/lib\n";
    my $exp = Expect->new;
    $exp = Expect->spawn("ssh -o StrictHostKeyChecking=no root\@$ip");

    # Step 1: Check path
    $exp->send("ls /opt/libevent/lib >/dev/null 2>&1 && echo OK || echo MISSING\n") if $exp->expect($expectT, '#');
    my $chk = $exp->before() // "";
    if ($chk =~ /MISSING/) {
        print "[$ip] ⚠ /opt/libevent/lib not found — skipping\n";
        $exp->send("exit\n") if $exp->expect($expectT, '#');
        $exp->soft_close();
        $pm->finish;
        next;
    }

    # Step 2: ensure ld.so.conf entry
    $exp->send("grep -q '/opt/libevent/lib' /etc/ld.so.conf.d/libevent.conf 2>/dev/null || echo '/opt/libevent/lib' > /etc/ld.so.conf.d/libevent.conf\n") 
        if $exp->expect($expectT, '#');

    # Step 3: refresh ldconfig
    $exp->send("ldconfig\n") if $exp->expect($expectT, '#');

    # Step 4: verify linkage
    $exp->send("ldconfig -p | grep -E 'libevent_core|libevent_pthreads' | grep '/opt/libevent' || echo 'NOT_FOUND'\n")
        if $exp->expect($expectT, '#');
    $exp->expect($expectT, -re => 'libevent_');
    my $res = $exp->before() // "";
    if ($res =~ /libevent_core/) {
        print "[$ip] ✅ libevent successfully registered in ldconfig.\n";
    } else {
        print "[$ip] ❌ libevent not found in ldconfig output!\n";
    }

    $exp->send("exit\n") if $exp->expect($expectT, '#');
    $exp->soft_close();
    $pm->finish;
}

# Also fix the master node itself
$pm->start and do {
    print ">>> [master] Checking local system...\n";
    system("grep -q '/opt/libevent/lib' /etc/ld.so.conf.d/libevent.conf 2>/dev/null || echo '/opt/libevent/lib' > /etc/ld.so.conf.d/libevent.conf");
    system("ldconfig");
    print ">>> [master] Verification:\n";
    system("ldconfig -p | grep -E 'libevent_core|libevent_pthreads' | grep '/opt/libevent'");
    $pm->finish;
};

$pm->wait_all_children;
print "\n=== libevent linkage check completed for all nodes ===\n";
