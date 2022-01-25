=Read this first !!!
please put this script and 2.5G Driver Package (r8125-9.004.01.tar.bz2) in /opt 
=cut
system (qq(dnf install elfutils* -y));
system(qq(tar jxvf r8125-9.004.01.tar.bz2));
system(qq(cd r8125-9.004.01 \n ./autorun.sh));
sleep(3);
system(qq(ifconfig | grep enp6s0));
if($?){die "!!!!! WARNING OH NO YOUR INSTALLATION IS FAILED !!!!!  MAYBE YOUR 2.5G NETCARD NAMED ANOTHER NAME? TRY TO CHECK BY HAND\n";}

else
{
    print qq(!!!  2.5G NETCARD DRIVER INSTALL GOOD  !!!\n);
}
