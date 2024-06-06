=b
https://linux.vbird.org/linux_basic/centos7/0420quota.php
for setting quota:
/dev/mapper/centos-home  /home  xfs  defaults,usrquota,grpquota   0 0
umount /home
mount -a
mount|grep home
/dev/mapper/centos-home on /home type xfs (rw,relatime,seclabel,attr2,inode64,usrquota,grpquota)
if not works, you need to reboot
=cut

use strict;
use warnings;
use Expect;
my $adduser = "yes";
my $setsmb = "yes";# you need to install 
#modify /etc/fatab for /home first
#,usrquota,grpquota then mount -a -o remount
my $setquota = "yes"; my $quota = "350";#use df -h to check first
my $bsoft = int(1024*$quota)."M"; my $bhard = int(1024*$quota + 1024*5)."M";

open my $ss,"< ./username.dat" or die "No Server_setting.dat to open.\n $!";#one line for an username
my @temp_array = <$ss>;
close $ss; 
my @user_accounts = grep (($_!~m{^\s*$|^#}),@temp_array); # remove blank lines

print "all new accounts:\n @user_accounts\n";
sleep(3);
#print "yes or no\n";
#my $stdin = <STDIN>;
#chomp $stdin;
#print "\$stdin: $stdin\n";
#if($stdin ne "yes"){
#   die "You don't provide the right response!\n";
#}
if($adduser eq "yes"){
    for my $new (@user_accounts){
        chomp $new;
        system("ps aux|grep -v grep|grep -v root|grep $new|awk '{print \$2}'|xargs kill");
        system("userdel -r $new");#-r flag to remove everything 
        system("rm -rf /home/$new"); 
        system("rm -rf /var/spool/mail/$new"); 
        system("useradd $new");
        system("echo $new | passwd $new --stdin");
        system("chage -d 0 $new");#force new user to change their passwd after first login
    }
}
sleep(1);
#samba setting
if($setsmb eq "yes"){
    my $expectT = 5;
    for my $new (@user_accounts){
        chomp $new;
        `pdbedit -x $new`;
        my $exp = Expect->new;
    	#$exp = Expect->spawn("pdbedit -x $new \n");
    	$exp ->spawn("pdbedit -a $new \n");# send("pdbedit -a $new \n") if ($exp->expect($expectT,"#"));
    	$exp -> send("$new\n") if ($exp->expect($expectT,"new password:"));
    	$exp -> send("$new\n") if ($exp->expect($expectT,"retype new password:"));
    	$exp -> send("\n");
        $exp->soft_close();
    }
    print "*** all current smb users\n";
    system("pdbedit -L");
    print "\n****Please use testparm to check your smb setting\n";
}
   
if($setquota eq "yes"){
    #system("xfs_quota -x -c \"print\"");
    #system("xfs_quota -x -c \"df -h\"");
    #system("xfs_quota -x -c \"state\"");#check quota state
    #system("xfs_quota -x -c \"report -ubih\" /home");#report quota for all
    for my $new (@user_accounts){    
        chomp $new;
        #print "xfs_quota -x -c \"limit -u bsoft=$bsoft bhard=$bhard $new \" /home\n";
        system("xfs_quota -x -c \"limit -u bsoft=$bsoft bhard=$bhard $new \" /home");#report quota for all
    }
    system("xfs_quota -x -c \"report -ubh\" /home");#report quota for all
}
#xfs_quota -x -c "report -ubh" /home
#xfs_quota -x -c "limit -u bsoft=2048 bhard=2080 Lin" /home