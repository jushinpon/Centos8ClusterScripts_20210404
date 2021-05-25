=b
you need to check the dev you want to use parted very carefully
1. df -h ---> the disk you are using
2. ls /dev/[sh]d* --> get the disk not listed above
3. fdisk -l /dev/xxx --> check new disk
4. blkid --> get disk uuid
https://rainbow.chard.org/2013/01/30/how-to-align-partitions-for-best-performance-using-parted/ 

parted -s -a opt /dev/sdb mklabel gpt mkpart 1 ext4 0% 100%

already mounted or mount point busy:
https://www.programmersought.com/article/62434144424/

cat /proc/partitions -> check if the dev has been used

dmsetup ls
=cut
use strict;
use warnings;

#######VERY IMPORTANT#######
#system("df -h");
#system("ls /dev/[sh]d*");
#die;
########

my $partedDev = "sda";
my $mount_path = "/freespace";
my $nfs = "no"; #yes or no, if yes, /etc/exports will be modified
my $type = "ext4"; 
my $install = `rpm -qa| grep "parted"`;
if (!$install){system("dnf install parted -y");} #if not installed

system("umount /dev/$partedDev");
system("parted -s -a opt /dev/$partedDev mklabel gpt mkpart 1 $type 0% 100%");
system("echo \"yes\"| mkfs.$type /dev/$partedDev");
  
my $blkid = `blkid`; #: UUID=\"(\w+)\"\s+
$blkid =~ /\/dev\/$partedDev:\s+UUID="(.*?)"/;# non-greedy match by?
chomp $1;
system("rm -rf /$mount_path/$partedDev");
system("mkdir /$mount_path/$partedDev");
system("chmod 777 /$mount_path/$partedDev");

### modify /etc/fstab
if(!`grep "$1" /etc/fstab`){
	`echo 'UUID=$1  /$mount_path/$partedDev $type defaults 0 0' >> /etc/fstab`;
	system("mount -a");
}
else{
	`sed -i '/$1/d' /etc/fstab`;
	`echo 'UUID=$1  /$mount_path/$partedDev $type defaults 0 0' >> /etc/fstab`;
	 system("mount -a");
}

#if($nfs eq "yes"){ 
#### modify /etc/exports
#	if(!`grep "$partedDev" /etc/exports`){
#		`echo "/$mount_path/$partedDev 192.168.0.0/24(rw,no_root_squash,no_subtree_check,async)" >> /etc/exports`;
#	}
#	else{
#		`sed -i '/\\/$partedDev/d' /etc/exports`;
#		`echo "/$mount_path/$partedDev 192.168.0.0/24(rw,no_root_squash,no_subtree_check,async)" >> /etc/exports`;   
#	} 
#	system("exportfs -auv"); # umount all first if you have mounted some previously!
#	system("exportfs -arv"); # make setting work!
#	system("exportfs -s"); # make setting work!
#}
# -v list all shared folders
#-a
# exportfs  -s : check all exported information
#showmount -e
########################## 
