#!/usr/bin/perl

system("dnf -y install vsftpd");
system("ssystemctl restart vsftpd");
system("ssystemctl enable vsftpd");

system("netstat -tul | grep ftp"); 
print "IF YOU SEE THE (LISTEN) AT YOUR RIGHT HAND SIDE, INSTALLATION IS CORRECT  ↑↑↑↑↑↑\n";
sleep(4);
chdir("/etc/vsftpd/");
system("perl -p -i.bak -e 's/\#?listen=.+/listen=NO/g' vsftpd.conf");
system("perl -p -i.bak -e 's/\#?write_enable.+/write_enable=YES/g'  vsftpd.conf");
system("perl -p -i.bak -e 's/\#?local_enable.+/local_enable=YES/g'  vsftpd.conf");
system("perl -p -i.bak -e 's/\#?local_umask=.+/local_umask=000/g'  vsftpd.conf");
#system("perl -p -i.bak -e 's/\#?ftb_banner=.+/ftb_banner=bigwind so good./g'  vsftpd.conf"); xxxx可以設定登入時的歡迎詞
system("systemctl restart vsftpd ");

system("firewall-cmd --permanent  --zone=external  --add-service=ftp");
system("firewall-cmd --reload");  

print "!!!!!!!  CENTOS VSFTP INSTALLATION ALL DONE !!!!!!\n";

 #check : system("ftp 140.117.xx.xxx"); xx.xxx is your local internet
