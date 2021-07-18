=b
If you create a new directory, such as a new top-level directory, label it
 with samba_share_t so that SELinux allows Samba to read and write to it. Do
 not label system directories, such as /etc/ and /home/, with samba_share_t, as
 such directories should already have an SELinux label.

 Run the "ls -ldZ /path/to/directory" command to view the current SELinux
 label for a given directory.

 Set SELinux labels only on files and directories you have created. Use the
 chcon command to temporarily change a label:
 chcon -t samba_share_t /path/to/directory
 1. enable root 使用者  : smbpasswd -e root
2. 確認目前samba的端口有哪些 netstat -ntlp |grep smb 
3. 添加防火牆規則  
    3-1 firewall-cmd --zone=external --add-port=%d/tcp --permanent 
    3-2 firewall-cmd --reload
    3-3 systemctl restart firewalld.service
4. 從windows登入時，登入網址為\\urip\[groupname]
5. root的samba密碼需與linux中的root密碼相同，方可從samba進入root資料夾
6. smbstatus: check status
7. smbclient -L localhost -N : check shared 
=cut

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

system("echo -e '\n'| testparm > smbCheck.txt");#for test the install process done or not 
system ("systemctl start smb");
system ("systemctl enable smb");
system ("setsebool -P samba_enable_home_dirs on");#share /home
system ("setsebool -P samba_domain_controller on");#enable root 
system ("setsebool -P samba_export_all_rw on");#enable system file writable
system ("testparm");#test smba
