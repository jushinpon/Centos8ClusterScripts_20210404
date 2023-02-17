use warnings;
use strict;
use Cwd; #Find Current Path

my @cmd = ("ps");
#my @cmd = ("ssh","top","htop","ps");

for (@cmd){
   # `chmod 750 /usr/bin/$_`;
    `chmod 751 /usr/bin/$_`;
}