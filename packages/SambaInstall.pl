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
make a group for permission
(base) [root@master ~]# usermod -g samba jsp
(base) [root@master ~]# usermod -g samba root
(base) [root@master ~]# chown -R root:samba /root
(base) [root@master ~]# chown -R jsp:samba /home/jsp
(base) [root@master ~]# chmod -R 775 /home/jsp
(base) [root@master ~]# chown -R root:samba /mnt
(base) [root@master ~]# chmod -R 775  /mnt
(base) [root@master ~]# systemctl restart smb
=cut

#!/usr/bin/perl
# smbpasswd: change smb passwd by each user (default passwd: mem4268)
use strict;
use warnings;
my $netbios_name = "182_master";

system ("systemctl stop smb");
system("yum install samba -y");
system("firewall-cmd --zone=external --add-port=139/tcp --permanent"); # for samba port
system("firewall-cmd --zone=external --add-port=445/tcp --permanent"); # for samba port
system ("firewall-cmd --reload"); #reload

my $ConfPath = '/etc/samba/smb.conf'; # path of smb.conf
system("rm -f $ConfPath");
system("touch $ConfPath");

#smb global setting
`echo '[global]
	workgroup = SAMBA
	netbios name = $netbios_name
	server string = SAMBA SERVER	 
	security = user
	unix extensions = no' >> $ConfPath
`;
#Home dir setting	
`echo '[homes]
comment = Home directories
browseable = no
writable = yes
valid users = %S
create mode = 0664
directory mode = 0775
' >> $ConfPath
`;
# / 
#`echo '[186_master]
#comment = / 
#browseable = yes
#writable = yes
#valid users = @samba
#create mode = 775
#directory mode = 775
#' >> $ConfPath
#`;

#	valid users = root
#	force user = root
#	force group = root
#	path = /
#	comment = Shared
#	browseable = yes
#	writable = yes
#	create mask = 0777
#	directory mask = 0777
#	read only = No
#	public = yes
#	follow symlinks = yes
#	write list = root
#	strict locking = no 
#	wide links = yes
#
#my $expectT = 5;
#foreach (@UserList){
#		chomp;
#		#system ("echo 'mem4268'|pdbedit -a -u $_"); #you need to set passwd for samba by hand 
#		print "\$defaultPass:$defaultPass\n";
#		my $exp = Expect->new;
#		$exp = Expect->spawn("pdbedit -a -u -e $_ \n");
#		$exp = Expect->spawn("smbpasswd -e $_ \n");
#		$exp -> send("$defaultPass\n") if ($exp->expect($expectT,"new password:"));
#		$exp -> send("$defaultPass\n") if ($exp->expect($expectT,"retype new password:"));
#		$exp -> send("\n");
#        $exp->soft_close();
#}

system("echo -e '\n'| testparm > smbCheck.txt");#for test the install process done or not 
system ("systemctl start smb");
system ("systemctl enable smb");
system ("setsebool -P samba_enable_home_dirs on");#share /home
system ("setsebool -P samba_domain_controller on");#enable root 
system ("setsebool -P samba_export_all_rw on");#enable system file writable
system ("testparm");#test smba
