use strict;
use warnings;
my $soft = "1024M";
my $hard = "1048M";
my @accounts = `xfs_quota -x -c "report -ubh" /home|egrep "^B|^M"|awk '{print \$1}'`;
chomp @accounts;
for (@accounts){
	#print "$_\n";
	`xfs_quota -x -c "limit -u bsoft=$soft bhard=$hard $_" /home`;
}
print "*** Show final quota setting\n\n";
system("xfs_quota -x -c \"report -ubh\" /home");
#xfs_quota -x -c "limit -u bsoft=2048 bhard=2080 Lin" /home
