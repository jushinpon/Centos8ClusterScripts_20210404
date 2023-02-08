system("yum install samba -y");
$ConfPath = '/etc/samba/smb.conf';
system("rm $ConfPath");
system("touch $ConfPath");

$filename = 'home';
$filepath = '/home';
$description = 'Shared';
$browseable = 'yes';
$readonly = 'no';
$Autority = '777';
$UserList = 'haha';
$hostallow = '140.117.59.184'; #maybe u don't need this because u have firewall,right?
@UserList = ("haha");

`echo "\n\[$filename\]" >> $ConfPath`;
`echo " comment = $description" >> $ConfPath`;
`echo " path = $filepath" >> $ConfPath`;
`echo " browseable = $browseable" >> $ConfPath`;
`echo " writable = $browseable" >> $ConfPath`;
`echo " create mask = $Autority" >> $ConfPath`;
`echo " directory mask = $Autority" >> $ConfPath`;
`echo " valid users = $UserList" >> $ConfPath`;

foreach (@UserList)
{
system ("pdbedit -a -u $_"); #you need to set passwd for samba by hand
}

`echo '
[global]
workgroup = SAMBA
netbios name = SAMBA_NETBIOS
server string = SAMBA SERVER
security = user' >> $ConfPath
`;
system("testparm");#for test the install process done or not
system("sudo setsebool -P samba_enable_home_dirs on");
##SELinux will block samba user to read home in first log in
#!!!!!!!!!!!!!!!!!! sudo setsebool -P samba_enable_home_dirs on !!!!!!!!!!!!!!!!




##DetailSet
=beg

hosts allow = $hostallow;
max connections = 10;
systemclt restart smb;

=cut

