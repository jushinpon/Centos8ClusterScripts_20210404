use strict;
use warnings;
use Parallel::ForkManager;
use Cwd;

my $forkNo = 4;  # 假设CPU有4个核心
my $pm = Parallel::ForkManager->new($forkNo);

my %nodes = (
    161 => [1..42],
    182 => [1..24],
    186 => [1..7],
    195 => [1..7],
    190 => [1..3],
    166 => [1..7]
);

my $ip = `/usr/sbin/ip a`;
$ip =~ /14\d\.1\d+\.\d+\.(\d+)/;
my $cluster = $1;
$cluster =~ s/^\s+|\s+$//;

my @allnodes = @{$nodes{$cluster}};
`/usr/bin/touch ~/scptest.dat`;

my @allgpu;
my @badgpu;
my @errgpu;

sub run_command {
    my ($cmd) = @_;
    my @output = `$cmd`;
    if ($?) {
        warn "Error executing command: $!";
        return ();
    }
    return @output;
}

for (@allnodes) {
    $pm->start and next;

    my $node_index = sprintf("%02d", $_);
    my $nodename = "node" . $node_index;
    my $cmd = "/usr/bin/ssh $nodename ";

    my @temp = run_command("timeout 10 $cmd '/usr/sbin/lspci|/usr/bin/egrep \"RTX 2080|RTX 3060|RTX 2060\"'");
    map { s/^\s+|\s+$//g; } @temp;

    if (@temp) {
        print "\n\n$nodename has a gpu card:\n";
        push @allgpu, $nodename;

        my @dkms_output = run_command("timeout 10 $cmd 'dkms status nvidia'");
        my $dkms_status = join("", @dkms_output);
        $dkms_status =~ s/^\s+|\s+$//g;
        print "dkms status nvidia:\n$dkms_status\n";

        if ($dkms_status !~ /installed/) {
            print "DKMS status for NVIDIA is not correctly installed on $nodename\n";
            push @badgpu, $nodename;
        } else {
            print "nvidia-smi:\n";
            my @temp1 = run_command("timeout 10 $cmd 'nvidia-smi|grep GPU'");
            my @temp2 = run_command("timeout 10 $cmd 'nvidia-smi|grep ERR'");
            print "nvidia-smi done\n";

            map { s/^\s+|\s+$//g; } @temp1;

            unless (@temp1) { push @badgpu, $nodename; }
            if (@temp2) { push @errgpu, $nodename; }
        }
    }

    $pm->finish;
}

print "\n\n***All GPU:\n";
print "$_\n" for @allgpu;

print "\n\n***Bad GPU:\n";
print "$_\n" for @badgpu;

print "\n\n***ERR GPU:\n";
print "$_\n" for @errgpu;
