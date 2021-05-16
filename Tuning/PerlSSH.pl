=b
Perl script to do the remote machine setting by using remote_setting.pl
or the file you assign
=cut

#!/usr/bin/perl
use strict;
use warnings;
use Parallel::ForkManager;

my $forkNo = 10;
my $pm = Parallel::ForkManager->new("$forkNo");
my $remote_perl = "remote_setting.pl";
#my $remote_perl = "parted.pl";
for (1..3){
    $pm->start and next;
    my $nodeindex=sprintf("%02d",$_);
    my $nodename= "node"."$nodeindex";
    my $cmd = "ssh $nodename ";
    system("scp  ./$remote_perl root\@$nodename:/root");
    if ($?){print "BAD: scp  $remote_perl root\@$nodename:/root failed\n";};
    system("$cmd 'perl $remote_perl > remote_setting.out'"); 
    system("$cmd 'cat remote_setting.out'"); 
    $pm->finish;
}
$pm->wait_all_children;

