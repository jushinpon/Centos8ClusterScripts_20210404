use strict;
use warnings;
use Parallel::ForkManager;
use Cwd;

# Adjust based on the cluster's capacity
my $forkNo = 1;
my $pm = Parallel::ForkManager->new($forkNo);

# Define nodes
my %nodes = (
    161 => [1..42],
    182 => [1..24],
    186 => [1..7],
    195 => [1..7],
    190 => [1..3],
    166 => [1..7]
);

# Get cluster ID from IP
my $ip_output = `/usr/sbin/ip a`;
$ip_output =~ /14\d\.1\d+\.\d+\.(\d+)/;
my $cluster = $1;
$cluster =~ s/^\s+|\s+$//;

# Retrieve nodes for this cluster
my @allnodes = @{$nodes{$cluster} // []};

my (@gpu_nodes, @bad_gpu_nodes);

for my $node (@allnodes) {
    $pm->start and next;

    my $nodeindex = sprintf("%02d", $node);
    my $nodename = "node$nodeindex";

    # Check if NVIDIA GPU exists using lspci
    my $gpu_check_cmd = "timeout 3 /usr/bin/ssh $nodename 'lspci | grep NV' 2>&1";
    my @gpu_check = `$gpu_check_cmd`;
    if ($? >> 8 || !@gpu_check) {
        $pm->finish;
    }

    # Check for GPU presence and get model
    my $gpu_info_cmd = "timeout 3 /usr/bin/ssh $nodename 'which nvidia-smi && nvidia-smi --query-gpu=name --format=csv,noheader' 2>&1";
    my @gpu_info = `$gpu_info_cmd`;
    s/^\s+|\s+$//g for @gpu_info;
    my $gpu_models = join(", ", @gpu_info);
    
    if ($gpu_models =~ /2060|2080|3060/) {
        push @gpu_nodes, "$nodename ($gpu_models)";

        # Check GPU health
        my $gpu_health_cmd = "timeout 3 /usr/bin/ssh $nodename 'nvidia-smi' 2>&1";
        my @gpu_health = `$gpu_health_cmd`;
        if (grep { /Failed to initialize NVML|GPU has fallen off the bus|Unable to establish connection/ } @gpu_health) {
            push @bad_gpu_nodes, "$nodename ($gpu_models)";
        }
    }
    
    $pm->finish;
}

$pm->wait_all_children;

# Summary Report
print "\n\n*** GPU Nodes:\n", join("\n\n", @gpu_nodes), "\n\n" if @gpu_nodes;
print "\n\n*** Bad GPU Nodes (Require Driver Reinstallation):\n", join("\n\n", @bad_gpu_nodes), "\n\n" if @bad_gpu_nodes;
