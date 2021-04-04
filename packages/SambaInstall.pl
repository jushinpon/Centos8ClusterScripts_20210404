#!/usr/bin/perl
# smbpasswd: change smb passwd by each user (default passwd: mem4268)
use strict;
use warnings;
use Expect;

system ("systemctl stop smb");
system("yum install samba -y");
system("firewall-cmd --zone=external --add-port=139/tcp --permanent"); # for samba port
system ("firewall-cmd --reload"); #reload

my $ConfPath = '/etc/samba/smb.conf'; # path of smb.conf
my @UserList = ("jsp","pitotech"); # the users (you want to use samba)
my @smb_obj = (["jsp","jsp","/home/jsp"]);# obj name, user (more than one is ok. like "jsp,pitotech"), and corresponding path

## some settings
my $defaultPass = "XXXXX";
my $description = 'Shared'; 
my $browseable = 'yes';
my $readonly = 'No';
my $Authority = '755';

system("rm -f $ConfPath");
system("touch $ConfPath");

#smb global setting
`echo '[global]
	workgroup = SAMBA
	netbios name = SAMBA_NETBIOS
	server string = SAMBA SERVER	 
	security = user' >> $ConfPath
	`;

for my $objID (0..$#smb_obj){
	#print "objID: $objID,$smb_obj[$objID][0], $smb_obj[$objID][1],$smb_obj[$objID][2]\n";
	chomp ($smb_obj[$objID][0], $smb_obj[$objID][1],$smb_obj[$objID][2]);
	
	`echo "\n\[$smb_obj[$objID][0]\]" >> $ConfPath`;
	`echo "	valid users = $smb_obj[$objID][1]" >> $ConfPath`;
	`echo "	path = $smb_obj[$objID][2]" >> $ConfPath`;
	`echo "	comment = $description" >> $ConfPath`;
	`echo "	browseable = $browseable" >> $ConfPath`;
	`echo "	writable = $browseable" >> $ConfPath`;
	`echo "	create mask = $Authority" >> $ConfPath`;
	`echo "	directory mask = $Authority" >> $ConfPath`;
	`echo "	read only = $readonly" >> $ConfPath`;	
}

my $expectT = 5;
foreach (@UserList){
		chomp;
		#system ("echo 'mem4268'|pdbedit -a -u $_"); #you need to set passwd for samba by hand 
		my $exp = Expect->new;
		$exp = Expect->spawn("pdbedit -a -u $_ \n");
		$exp -> send("$defaultPass\n") if ($exp->expect($expectT,"new password:"));
		$exp -> send("$defaultPass\n") if ($exp->expect($expectT,"retype new password:"));
		$exp -> send("\n");
        $exp->soft_close();
}

system("echo -e '\n'| testparm > smbCheck.txt");#for test the install process done or not 
system ("systemctl start smb");
system ("systemctl enable smb");
system ("setsebool -P samba_enable_home_dirs on");
