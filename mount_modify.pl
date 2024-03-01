use Parallel::ForkManager;
use Cwd;
#my $currentPath = getcwd();
$forkNo = 1;
my $pm = Parallel::ForkManager->new("$forkNo");
my @mount = `grep node /etc/fstab`;
map { s/^\s+|\s+$//g; } @mount;
%mount;
for (@mount){
    my @temp = split(/\s+/,$_);
    $_ =~ m/(node\d+):.+?\s+(\/mnt.+?)\s+nfs\s+noacl.+/;
    push @{$mount{$1}},$2;
}

my %nodes = (
    161 => [1..42],#1,3,39..
    #161 => [22,30],#1,3,39..
    182 => [1..24],
    186 => [1..7],
    195 => [1..7],
    190 => [1..3]
    );

my $ip = `/usr/sbin/ip a`;    
$ip =~ /14\d\.1\d+\.\d+\.(\d+)/;
my $cluster = $1;
$cluster =~ s/^\s+|\s+$//;
my @allnodes = @{$nodes{$cluster}};#get node information
for (@allnodes){
    $nodeindex=sprintf("%02d",$_);
    $nodename= "node"."$nodeindex";
    print "****Check $nodename status\n ";    
    system("/usr/sbin/ping -c 1 $nodename");
    if($?){#get ping error!
        for my $l (@{$mount{$nodename}}){
            print "$l\n";
            if(`mount|grep $l`){`umount -l $l`}
        }
    }
    else{#no ping error
        for my $l (@{$mount{$nodename}}){
            unless(`mount|grep $l`){`mount $l`}
        }
    }
}