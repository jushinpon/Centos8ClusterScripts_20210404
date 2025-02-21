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

my (@gpu_nodes, @badgpu, @errgpu, @unreachable_nodes, @reinstall_nodes);

for my $node (@allnodes) {
    $pm->start and next;

    my $nodeindex = sprintf("%02d", $node);
    my $nodename = "node$nodeindex";
    my $cmd = "/usr/bin/ssh $nodename ";

    # Check if node is reachable
    my $ping_test = `timeout 5 ping -c 1 $nodename 2>&1`;
    if ($? >> 8) {
        warn "Node $nodename is unreachable.\n";
        push @unreachable_nodes, $nodename;
        $pm->finish;
    }

    # Check for GPU presence and get model
    my @gpu_info = `$cmd 'which nvidia-smi && nvidia-smi --query-gpu=name --format=csv,noheader' 2>&1`;
    print "Raw GPU output for $nodename:\n@gpu_info\n";  # Debugging line

    if ($? >> 8) {
        warn "Error executing nvidia-smi on $nodename.\n";
        push @reinstall_nodes, $nodename;  # Mark for driver reinstallation
        $pm->finish;
    }

    s/^\s+|\s+$//g for @gpu_info;
    my $gpu_models = join(", ", @gpu_info);
    
    if ($gpu_models) {
        push @gpu_nodes, "$nodename ($gpu_models)";

        # Check DKMS status
        my $dkms = `timeout 10 $cmd 'dkms status nvidia' 2>&1`;
        $dkms =~ s/^\s+|\s+$//g;
        
        # Run nvidia-smi and process output
        my @nvidia_output = `timeout 10 $cmd 'nvidia-smi' 2>&1`;
        
        # Check for driver/library mismatch error
        my $nvml_error = grep { /Failed to initialize NVML: Driver\/library version mismatch/ } @nvidia_output;
        if ($nvml_error) {
            warn "Driver/library version mismatch on $nodename.\n";
            push @reinstall_nodes, "$nodename ($gpu_models)";  # Mark for reinstallation
            $pm->finish;
        }

        if ($? >> 8) {
            push @badgpu, "$nodename ($gpu_models)";
            $pm->finish;
        }

        s/^\s+|\s+$//g for @nvidia_output;
        my $has_error = grep { /ERR|Fail/ } @nvidia_output;

        push @errgpu, "$nodename ($gpu_models)" if $has_error;
    } else {
        warn "No GPU detected or command failed on $nodename.";
        push @reinstall_nodes, $nodename;  # Mark for reinstallation
    }

    $pm->finish;
}

$pm->wait_all_children;

# Summary Report
print "\n\n*** GPU Nodes:\n", join("\n", @gpu_nodes), "\n" if @gpu_nodes;
print "\n\n*** Bad GPU Nodes:\n", join("\n", @badgpu), "\n" if @badgpu;
print "\n\n*** ERR GPU Nodes:\n", join("\n", @errgpu), "\n" if @errgpu;
print "\n\n*** Unreachable Nodes:\n", join("\n", @unreachable_nodes), "\n" if @unreachable_nodes;
print "\n\n*** Nodes Needing GPU Driver Reinstallation:\n", join("\n", @reinstall_nodes), "\n" if @reinstall_nodes;
