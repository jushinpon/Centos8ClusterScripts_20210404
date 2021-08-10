use strict;
use warnings;
use Expect;
my $adduser = "yes";
my $setsmb = "yes";
#modify /etc/fatab for /home first
#,usrquota,grpquota then mount -a -o remount
my $setquota = "yes"; my $quota = "40";#use df -h to check first

open my $ss,"< ./username.dat" or die "No Server_setting.dat to open.\n $!";#one line for an username
my @temp_array = <$ss>;
close $ss; 
my @user_accounts = grep (($_!~m{^\s*$|^#}),@temp_array); # remove blank lines

print "all new accounts: @user_accounts\n";
print "yes or no\n";
my $stdin = <STDIN>;
chomp $stdin;
print "\$stdin: $stdin\n";
if($stdin ne "yes"){
   die "You don't provide the right response!\n";
}
if($adduser eq "yes"){
    for my $new (@user_accounts){
        chomp $new;
        system("userdel $new");#-r flag to remove everything
        system("useradd $new");
        system("echo $new | passwd $new --stdin");
        system("chage -d 0 $new");#force new user to change their passwd after first login
    }
}

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
   
   
system("pdbedit -L");
