#!/bin/sh
use warnings;
use strict;
use Cwd; #Find Current Path

my @cmd = ("ssh","top","htop","ps");

for (@cmd){
    `chmod 750 /usr/bin/htop`;
    #`chmod 751 /usr/bin/htop`;
}