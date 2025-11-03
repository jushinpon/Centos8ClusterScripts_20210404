#!/usr/bin/perl
=b
the installation order: 1. libevent 2. pmix 3. slurm

export PATH=/opt/pmix/current/bin:$PATH
export LD_LIBRARY_PATH=/opt/pmix/current/lib:$LD_LIBRARY_PATH
=cut

use strict;
use warnings;
use File::Path qw(remove_tree);
use File::Find;

print "===============================================\n";
print "  PMIx + libevent Cleanup Script for HPC Nodes\n";
print "  Author: Prof. Shin-Pon Ju (auto-generated)\n";
print "===============================================\n";

# --- Targets to check ---
my @pmix_paths = (
    "/opt/pmix", "/usr/local/pmix",
    "/usr/local/lib/pmix", "/usr/local/lib64/pmix"
);
my @libevent_paths = (
    "/opt/libevent", "/usr/local/libevent",
    "/usr/local/lib/libevent", "/usr/local/lib64/libevent"
);
my @ldconf_files = (
    "/etc/ld.so.conf.d/pmix.conf",
    "/etc/ld.so.conf.d/libevent.conf"
);

# --- remove PMIx ---
print "\n>>> Removing PMIx installations...\n";
for my $dir (@pmix_paths) {
    if (-d $dir) {
        print "  - Found: $dir  -> removing...\n";
        remove_tree($dir, {error => \my $err});
        if (@$err) {
            warn "    ⚠️  Some files could not be removed in $dir\n";
        }
    }
}

# --- remove libevent ---
print "\n>>> Removing libevent installations...\n";
for my $dir (@libevent_paths) {
    if (-d $dir) {
        print "  - Found: $dir  -> removing...\n";
        remove_tree($dir, {error => \my $err});
        if (@$err) {
            warn "    ⚠️  Some files could not be removed in $dir\n";
        }
    }
}

# --- remove stray symlinks ---
print "\n>>> Cleaning stray symlinks under /usr/lib64 and /usr/local/lib...\n";
my @lib_dirs = ("/usr/lib64", "/usr/local/lib", "/usr/local/lib64");
for my $libdir (@lib_dirs) {
    next unless -d $libdir;
    find(
        sub {
            my $f = $File::Find::name;
            if (-l $f && $f =~ /lib(pm ix|event).*\.so/i) {
                print "  - Removing symlink: $f\n";
                unlink $f;
            }
        },
        $libdir
    );
}

# --- remove ld.so.conf entries ---
print "\n>>> Removing ld.so.conf.d entries...\n";
for my $f (@ldconf_files) {
    if (-e $f) {
        print "  - Deleting $f\n";
        unlink $f or warn "    ⚠️  Could not delete $f: $!\n";
    }
}

# --- final ldconfig ---
print "\n>>> Running ldconfig to refresh linker cache...\n";
system("ldconfig");
print "\n>>> Current status:\n";
system("ls /opt/pmix");
system("ls /opt/libevent");
system("ls /etc/ld.so.conf.d/ | grep -E 'pmix|libevent'");
system("ldconfig -p | grep -E 'pmix|event'|grep -v lib64");


print "\n✅ Cleanup complete.\n";
print "You may now safely reinstall libevent and PMIx.\n";
print "Recommended order:\n";
print "  1. Build libevent → /opt/libevent\n";
print "  2. Build PMIx → /opt/pmix/current\n";
print "Then rerun: ldconfig && srun --mpi=list\n";
print "===============================================\n";
