=b
This script helps you build the mergerfs 
1. https://github.com/trapexit/mergerfs --> check the latest version
=cut
use strict;
use warnings;
use Cwd;

my %disk_UUID;
for (`blkid|grep \"sd[a-z]\"`){
	chomp;
	/(sd[a-z][1-9]?).+UUID="(.+?)"/;
	chomp ($1,$2);
	#print "$1 => UUID: $2\n";
	$disk_UUID{$1} = "$2";
	#print "$1 => UUID: $disk_UUID{$1}\n";
	if(!$1 or !$2){die "You don't get $1 or $2\n";}	
}

my $wgetORgit = "no";
my $packageDir = "/home/packages";
if(!-e $packageDir){# if no /home/packages, make this folder	
	system("mkdir $packageDir");	
}

my $URL = "https://github.com/trapexit/mergerfs/releases/download/2.32.4/mergerfs-2.32.4-1.el8.x86_64.rpm";#url to download
my $Dir4download = "$packageDir/mergerfs_download"; #the directory we download Mpich
my $currentPath = getcwd(); #get perl code path
####### in the directory of $lammps_download
if($wgetORgit eq "yes"){
	system ("rm -rf $Dir4download");# remove the older directory first
	system("mkdir $Dir4download");# make a directory in current path
	chdir("$Dir4download");# cd to this dir for downloading the packages
	system("wget $URL lammps");
	chdir("$currentPath");# cd to this dir for downloading the packages
}

chdir("$Dir4download");
system("dnf localinstall -y ./mergerfs*");
if($?){die "install mergerfs failed\n";}

my %mergerfs = (
    server => ["mnt","sda","sdb","sdd","sde","sdf","sdg"],
	node01 => ["/free","/sdb","/sdb",2,10,2],#8G,/free:888G,/sdb:931Gib
	node02 => ["/free","/sda","/sda",3,10,2],#16G,/free:878G,/sda:1.7T 
	node03 => ["/free","/sda","/sda",3,10,2] #16G,/free:878G,/sda:870G
#	#node02 => [ ]	
	);
#	
#if(	$server_createplot eq "yes"){
#
########VERY IMPORTANT#######
##system("df -h");
##system("ls /dev/[sh]d*");
##die;
#########
#
#my $partedDev = "sdg";
#my $mount_path = "/freespace";
#my $nfs = "no"; #yes or no, if yes, /etc/exports will be modified
#my $type = "ext4"; 
##my $install = `rpm -qa| grep "parted"`;
##if (!$install){system("dnf install parted -y");} #if not installed
#
#system("umount -l /dev/$partedDev");
#system("parted -s -a opt /dev/$partedDev mklabel gpt mkpart 1 $type 0% 100%");
#system("echo \"yes\"| mkfs.$type /dev/$partedDev");
#
#die;  
#my $blkid = `blkid`; #: UUID=\"(\w+)\"\s+
#$blkid =~ /\/dev\/$partedDev:\s+UUID="(.*?)"/;# non-greedy match by?
#chomp $1;
#system("rm -rf /$mount_path/$partedDev");
#system("mkdir /$mount_path/$partedDev");
#system("chmod 777 /$mount_path/$partedDev");
#
#### modify /etc/fstab
#if(!`grep "$1" /etc/fstab`){
#	`echo 'UUID=$1  /$mount_path/$partedDev $type defaults 0 0' >> /etc/fstab`;
#	system("mount -a");
#}
#else{
#	`sed -i '/$1/d' /etc/fstab`;
#	`echo 'UUID=$1  /$mount_path/$partedDev $type defaults 0 0' >> /etc/fstab`;
#	 system("mount -a");
#}
#
##if($nfs eq "yes"){ 
##### modify /etc/exports
##	if(!`grep "$partedDev" /etc/exports`){
##		`echo "/$mount_path/$partedDev 192.168.0.0/24(rw,no_root_squash,no_subtree_check,async)" >> /etc/exports`;
##	}
##	else{
##		`sed -i '/\\/$partedDev/d' /etc/exports`;
##		`echo "/$mount_path/$partedDev 192.168.0.0/24(rw,no_root_squash,no_subtree_check,async)" >> /etc/exports`;   
##	} 
##	system("exportfs -auv"); # umount all first if you have mounted some previously!
##	system("exportfs -arv"); # make setting work!
##	system("exportfs -s"); # make setting work!
##}
## -v list all shared folders
##-a
# exportfs  -s : check all exported information
#showmount -e
########################## 
