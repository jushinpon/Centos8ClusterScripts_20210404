# ssh nodeXXX test
#nohup ifdown enp1s0 down && ifup enp1s0 up &

use Parallel::ForkManager;
use Cwd;
#my $currentPath = getcwd();
$forkNo = 1;
my $pm = Parallel::ForkManager->new("$forkNo");

my @allnodes = (1..24);
my @badnodes = (28..31);
my @nodes;
for my $a (@allnodes){
    chomp $a;
    my $index = 1;	
    for my $b (@badnodes){
        chomp $b;
        $index = 0 if($a == $b);
    }
  push @nodes, $a  if($index == 1);
} 

for (@nodes){
$pm->start and next;
$nodeindex=sprintf("%02d",$_);
$nodename= "node"."$nodeindex";
print "$nodename\n";
$cmd = "ssh $nodename ";
`$cmd "ps aux|grep -v grep|egrep \\\"lammps|QEGCC\\\"|awk '{print \\\$2}'"`;#|xargs kill
#system("$cmd 'ps aux|grep \"opt\"'");#|awk \'{print \\\$2}\'|xargs kill'");
   $pm->finish;
}
$pm->wait_all_children;
