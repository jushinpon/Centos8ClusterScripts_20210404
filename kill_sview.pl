# install slurm for adding new nodes to cluster

use warnings;
use strict;

my @sview = `ps aux|grep sview|awk '{print \$2}'`;
map { s/^\s+|\s+$//g; } @sview;
if(@sview){
    for (@sview){
        print "***sview id: $_\n";
        `kill -9 $_`;
    }
}
