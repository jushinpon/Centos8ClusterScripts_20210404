my @badgpu = qw(node01
node03
node09
node12
node14
node16
node17
node18
node20
node39);

for (@badgpu){
    print "$_\n";
    `scontrol update node=$_ state=drain reason=gpu_check`;
}