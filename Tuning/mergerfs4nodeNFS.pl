=b
This script helps you build the mergerfs 
1. https://github.com/trapexit/mergerfs --> check the latest version

You need to conduct NFSnode4server.pl andNFSnode4server_mount.pl in advance.
=cut
use strict;
use warnings;
use Cwd;

my $centVer= `cat /etc/redhat-release`;
$centVer =~ /release\s+(\d)\.\d+\.\d+.+/;
chomp $1;
my $currentVer = $1;
#print "Centos Version: $currentVer\n";
#
if($currentVer eq "8"){
	system("sed -i -e \"s|mirrorlist=|#mirrorlist=|g\" /etc/yum.repos.d/CentOS-*");
	system("sed -i -e \"s|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g\" /etc/yum.repos.d/CentOS-*");
	system("dnf clean all");
}

#install mergerfs rpm
my $wgetORgit = "yes";
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
	system("wget $URL");
	chdir("$Dir4download");
	system("dnf localinstall -y ./mergerfs*");
	if($?){die "install mergerfs failed\n";}
	chdir("$currentPath");# cd to this dir for downloading the packages
}

chdir("$currentPath");# cd to this dir for downloading the packages

my @mergerAll = `find /mnt/nodes_nfs/ -maxdepth 2 -mindepth 2 -type d -name "*"`;
chomp @mergerAll;
#for (@mergerAll){
#	print "$_\n";
#}

### making mergerfs folder
my $mergerAll = join(":",@mergerAll);
chomp $mergerAll;
my $merger4fstab = "/mnt/merger_nodedisk ".
				   "fuse.mergerfs ".
				   "defaults,auto,allow_other,use_ino,".
				   "minfreespace=1M,ignorepponrename=true 0 0";
chomp $merger4fstab;				   
system("umount -l /mnt/merger_nodedisk");
system("mkdir -p /mnt/merger_nodedisk");
#system("chmod -R 777 /mnt/merger_nodedisk");
#system("chmod -R 777 /mnt/nodes_nfs");

`sed -i '/merger_nodedisk/d' /etc/fstab`;
`echo '$mergerAll $merger4fstab' >> /etc/fstab`;
`sed -i '/^\$/d' /etc/fstab`;
#if(!`grep "$mergerAll" /etc/fstab`){
#		`echo '$mergerAll $merger4fstab' >> /etc/fstab`;
#		#system("mount -a");
#	}
#	else{
#		
#	}
#
print "$mergerAll $merger4fstab\n";
system("mount -a");	

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
