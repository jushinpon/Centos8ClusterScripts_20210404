=b
This script helps you build the mergerfs 
1. https://github.com/trapexit/mergerfs --> check the latest version
=cut
use strict;
use warnings;
use Cwd;

my %nfs = (# disks you want to share with server
	node01 => ["free","sdb"],
	node02 => ["free","sda"],
	node03 => ["free","sda"] 
	);

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
chdir("$currentPath");# cd to this dir for downloading the packages

my @mergerAll;

for my $nodename (sort keys %nfs){
	chomp $nodename;
	print "***host: $nodename\n";
	#system("mkdir -p /mnt/nodes_nfs/$nodename"); 

	for my $folder ( @{$nfs{$nodename}} ){
		print "folder: $folder\n";
		push @mergerAll,"/mnt/nodes_nfs/$nodename/$folder";
	}	
}


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
system("chmod -R 777 /mnt/merger_nodedisk");
system("chmod -R 777 /mnt/nodes_nfs");

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
#system("mount -a");	

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
