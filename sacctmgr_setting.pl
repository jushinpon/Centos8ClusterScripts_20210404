=b
systemctl status maridb
cp my.cnf to /etc/my.cnf.d/
systemctl restart maridb
systemctl enable maridb

=cut

use strict;
use warnings;
use Expect;
my $adduser = "no";
my $setsmb = "yes";# you need to install 
#modify /etc/fatab for /home first
#,usrquota,grpquota then mount -a -o remount
my $setquota = "no"; my $quota = "100";#use df -h to check first
my $bsoft = int(1024*$quota)."M"; my $bhard = int(1024*$quota + 1024*5)."M";

open my $ss,"< ./username.dat" or die "No Server_setting.dat to open.\n $!";#one line for an username
my @temp_array = <$ss>;
close $ss; 
my @user_accounts = grep (($_!~m{^\s*$|^#}),@temp_array); # remove blank lines
