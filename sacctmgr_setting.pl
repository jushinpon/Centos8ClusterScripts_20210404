=b
For the first use slurmdbd, you need to create an account before adding user
sacctmgr add account mel Description="MEL" Organization="MEME"

systemctl status maridb
cp my.cnf to /etc/my.cnf.d/
systemctl restart maridb
systemctl enable maridb

sacctmgr modify -i user name=jsp set MaxJobs=2
=cut

use strict;
use warnings;

my $adduser = "yes";
my $maxjobs = 20;
open my $ss,"< ./username.dat" or die "No Server_setting.dat to open.\n $!";#one line for an username
my @temp_array = <$ss>;
close $ss; 
my @user_accounts = grep (($_!~m{^\s*$|^#}),@temp_array); # remove blank lines
chomp @user_accounts;
for (@user_accounts){
    #print "$_\n";
    #system("sacctmgr -i add user $_ DefaultAccount=mel set MaxJobs=$maxjobs");
    system("sacctmgr -i modify user $_ set MaxJobs=$maxjobs");
}
