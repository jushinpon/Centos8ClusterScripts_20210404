=b
dnf install cifs-utils
mkdir -p /mnt/185_win/d
mount -t cifs -o username="Shin-Pon Ju" //140.117.59.185/d /mnt/185_win/d
=cut

#!/usr/bin/perl

use strict;
use warnings;
use Expect;#Password for

system ("dnf install cifs-utils");


my @machineIP = qw (
["140.117.59.185",5,"d","e","f","i","k"]
);
my %user4machine = (140.117.59.185 => ["Shin-Pon Ju","mem4268Ju?\#*"]);
#umount old first


#make mount folder


my $ConfPath = '/etc/samba/smb.conf'; # path of smb.conf
my @UserList = ("root"); # the users (you want to use samba)
my @smb_obj = (["190_master","root","/"]);# obj name, user (more than one is ok. like "jsp,pitotech"), and corresponding path

## some settings
my $defaultPass = "XXXXX";
my $description = 'Shared'; 
my $browseable = 'yes';
my $readonly = 'No';
my $Authority = '0777';

system("rm -f $ConfPath");
system("touch $ConfPath");

#smb global setting
`echo '[global]
	workgroup = SAMBA
	netbios name = 190_master
	server string = SAMBA SERVER	 
	security = user
	unix extensions = no' >> $ConfPath
	`;

for my $objID (0..$#smb_obj){
	#print "objID: $objID,$smb_obj[$objID][0], $smb_obj[$objID][1],$smb_obj[$objID][2]\n";
	chomp ($smb_obj[$objID][0], $smb_obj[$objID][1],$smb_obj[$objID][2]);
	
	`echo "\n\[$smb_obj[$objID][0]\]" >> $ConfPath`;
	`echo "	valid users = $smb_obj[$objID][1]" >> $ConfPath`;
	`echo "	force user = $smb_obj[$objID][1]" >> $ConfPath`;
	`echo "	path = $smb_obj[$objID][2]" >> $ConfPath`;
	`echo "	comment = $description" >> $ConfPath`;
	`echo "	browseable = $browseable" >> $ConfPath`;
	`echo "	writable = $browseable" >> $ConfPath`;
	`echo "	create mask = $Authority" >> $ConfPath`;
	`echo "	directory mask = $Authority" >> $ConfPath`;
	`echo "	read only = $readonly" >> $ConfPath`;
	`echo "	public = yes" >> $ConfPath`;
	`echo "	follow symlinks = yes" >> $ConfPath`;
	`echo "	strict locking = no" >> $ConfPath`;
	`echo "	wide links = yes" >> $ConfPath`;
	#write list = root		
}

my $expectT = 5;
foreach (@UserList){
		chomp;
		#system ("echo 'mem4268'|pdbedit -a -u $_"); #you need to set passwd for samba by hand 
		print "\$defaultPass:$defaultPass\n";
		my $exp = Expect->new;
		$exp = Expect->spawn("pdbedit -a -u -e $_ \n");
		$exp = Expect->spawn("smbpasswd -e $_ \n");
		$exp -> send("$defaultPass\n") if ($exp->expect($expectT,"new password:"));
		$exp -> send("$defaultPass\n") if ($exp->expect($expectT,"retype new password:"));
		$exp -> send("\n");
        $exp->soft_close();
}

