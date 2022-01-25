=Read this first !!!
please put this script and 1G Driver Package (r8168.tar.bz2) in /opt 
=cut
system (qq(dnf install elfutils* -y));
system(qq(tar jxvf r8168.tar.bz2));
system(qq(cd r8168 \n ./autorun.sh));
sleep(3);
system(qq(ifconfig | grep enp6s0));
if($?){die "!!!!! WARNING OH NO YOUR INSTALLATION IS FAILED !!!!!  MAYBE YOUR 1G NETCARD NAMED ANOTHER NAME? TRY TO CHECK BY HAND\n";}

else
{
    print qq(!!!  1G NETCARD DRIVER INSTALL GOOD  !!!\n);
}
