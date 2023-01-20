=b
For server only!
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
tune2fs -r $((100*1024*1024/4096)) /dev/sdb1 :adjust disk size for ext4
=cut
use strict;
use warnings;

my $parted = "no";
my $mount = "yes";
#######VERY IMPORTANT#######
#system("df -h");
#system("ls /dev/[sh]d*");
#die;
########
my @disks = ("sda","sdb","sdc","sde","sdf","sdg");
my $mount_path = "/mnt/master";
my $type = "ext4"; 
#my $install = `rpm -qa| grep "parted"`;
#if (!$install){system("dnf install parted -y");} #if not installed

#formatting
if($parted eq "yes"){ 
	for my $partedDev (@disks){
		chomp $partedDev;
		#system("umount -l /dev/$partedDev");
		#system("parted -s -a opt /dev/$partedDev mklabel gpt mkpart 1 $type 0% 100%");
		#system("echo \"yes\"| mkfs.$type /dev/$partedDev");
	}
} 

#modify fstab and mount 
if($mount eq "yes"){ 
	for my $partedDev (@disks){
		my $blkid = `blkid|grep "/dev/$partedDev"|awk -v FS=\\" '{print \$2}'`; #: UUID=\"(\w+)\"\s+
		chomp $blkid;
		print "***$partedDev \$blkid: $blkid\n";
		#$blkid =~ /\/dev\/$partedDev:\s+UUID="(.*?)"/;# non-greedy match by?
		system("mkdir -p $mount_path/$partedDev");
		
		### modify /etc/fstab
		if(!`grep "$blkid" /etc/fstab`){
			`echo 'UUID=$blkid  $mount_path/$partedDev $type defaults 0 0' >> /etc/fstab`;
			system("mount -a");
		}
		else{
			`sed -i '/$blkid/d' /etc/fstab`;
			`echo 'UUID=$blkid  $mount_path/$partedDev $type defaults 0 0' >> /etc/fstab`;
			system("mount -a");
		}
	}
}
