=b
You need to check which devs you want to format very carefully. Use ssh_install.pl to check it first.

use PerlSSH.perl to scp this script to the node you want to conduct
parted command.

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
#my $install = `rpm -qa| grep "parted"`;
#if (!$install){system("dnf install parted -y");} #if not installed
=cut
use strict;
use warnings;

my %partedDevs = (# disks you want to share with server
	node01 => ["sdc","sdd"],
	node02 => ["sdc","sdd"], 
	node03 => ["sdc"] 
	);
my $hostname = `hostname`;
chomp $hostname;

my $mount_path = "/mnt";
my $type = "ext4"; 

#formatting
for my $partedDev ( @{$partedDevs{$hostname}} ){
	chomp $partedDev;
	system("umount -l /dev/$partedDev");
	system("parted -s -a opt /dev/$partedDev mklabel gpt mkpart 1 $type 0% 100%");
	system("echo \"yes\"| mkfs.$type /dev/$partedDev");
}

# modify fstab and mount
for my $partedDev ( @{$partedDevs{$hostname}} ){
	chomp $partedDev;
	my $blkid = `blkid`; #: UUID=\"(\w+)\"\s+
	$blkid =~ /\/dev\/$partedDev:\s+UUID="(.*?)"/;# non-greedy match by?
	chomp $1;
	#system("rm -rf /$mount_path/$partedDev");
	system("mkdir -p /$mount_path/$partedDev");
	
	### modify /etc/fstab
	if(!`grep "$1" /etc/fstab`){
		`echo 'UUID=$1  $mount_path/$partedDev $type defaults 0 0' >> /etc/fstab`;
		system("mount -a");
	}
	else{
		`sed -i '/$1/d' /etc/fstab`;
		`echo 'UUID=$1  $mount_path/$partedDev $type defaults 0 0' >> /etc/fstab`;
		system("mount -a");
	}
}
