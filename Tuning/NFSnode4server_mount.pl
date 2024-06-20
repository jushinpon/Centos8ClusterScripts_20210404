=b
Perl script to mount all NSF folders of nodes.
You should export all folders in the nodes first using NFSnode4server.pl.
=cut

#!/usr/bin/perl
use strict;
use warnings;
use Parallel::ForkManager;
#my @nodes = 1..3;
my @mounted = `mount|grep "^node"|awk '{print \$1}'`;
chomp @mounted;

for (@mounted){
	print "umount $_\n";
	system("umount -l $_");
}

my $forkNo = 10;

my %nodes = (
    161 => [1..42],#1,3,39..
    182 => [1..24],
    186 => [1..7],
    190 => [2..3]
    );

my $ip = `/usr/sbin/ip a`;    
$ip =~ /140\.117\.\d+\.(\d+)/;
my $cluster = $1;
$cluster =~ s/^\s+|\s+$//;
my @allnodes = @{$nodes{$cluster}};#get node information

`touch ./scptest.dat`;#make a scp test file to skip bad nodes

my @nodes;
my $nodeindex;
my $nodename;
my $cmd;

for (@allnodes){
    chomp;
	$nodeindex=sprintf("%02d",$_);
    $nodename= "node"."$nodeindex";
    $cmd = "/usr/bin/ssh $nodename ";
    print "****Check $nodename status\n ";
    #`echo "***$nodename" >> $output`;
#use scp for ssh test
	system("scp -o ConnectTimeout=5 ~/scptest.dat root\@$nodename:/root");    
    if($?){
		print "scp at $nodename failed\n";
		next;
	}
	else{
		print "scp at $nodename ok for ssh test\n";
  		push @nodes, $_;
	}	
} 

chomp @nodes;

my %nfs;
for (@nodes){
    my $nodeindex = sprintf("%02d",$_);
    my $nodename = "node"."$nodeindex";
    $cmd = "/usr/bin/ssh $nodename ";
	my @temp = `$cmd 'ls /|grep free|grep -v grep'`; 
	chomp @temp;
	#print "###temp: @temp\n";       
	if(@temp){
		$nfs{$nodename} = ["free"];
		system("umount -l $nodename:/free");#umount all nfs folders 
	}
	else{
		die "no free folder in $nodename\n";
	}
	my @mnt = `$cmd 'ls /mnt'`;
	chomp @mnt;
	print "@mnt\n";
	for my $d (@mnt){
		push @{$nfs{$nodename}},$d;	
		system("umount -l $nodename:/mnt/$d");#umount all nfs folders 
	}
	print "***dev at $nodename: @{$nfs{$nodename}}\n";
	#$nfs{$nodename} = ["free"];
	#system("umount -l $nodename:/free");#umount all nfs folders 
}

my $mount_setting = "nfs noacl,nocto,nosuid,noatime,nodiratime,".
					"_netdev,auto,bg,soft,rsize=32768,wsize=32768 0 0"; 	
#`echo master:/home /home nfs noacl,nocto,nosuid,noatime,nodiratime,_netdev,auto,bg,soft,rsize=32768,wsize=32768 0 0 >> /etc/fstab`;

## modify fstab to original one first
`sed -i '/^node.*:.*/d' /etc/fstab`;
`sed -i '/nodes_nfs/d' /etc/fstab`;
#remove all old nfs folders under /mnt/nodes_nfs/
`rm -rf  /mnt/nodes_nfs/*`;

#my @folders = `find /mnt/nodes_nfs/ -maxdepth 1 -mindepth 1 -type d -name "*"`;
#chomp @folders;
#for (@folders){
#	system("umount -l $nodename:/$folder");	
#	print "$_\n";
#}
my $nfs_dir = "/mnt/nodes_nfs";
system("mkdir -p $nfs_dir");
`echo " " >> /etc/fstab`;#make a blank line first.
 
#system("chmod -R 777 $nfs_dir"); 
for (@nodes){
    my $nodeindex = sprintf("%02d",$_);
    my $nodename = "node"."$nodeindex";
	chomp $nodename;
	print "\n***host: $nodename\n";
	system("mkdir -p /mnt/nodes_nfs/$nodename"); 

	for my $folder ( @{$nfs{$nodename}} ){
		chomp $folder;
		print "folder: $folder\n";
		if($folder eq "free"){
			system("umount -l $nodename:/$folder"); 
			system("mkdir -p /mnt/nodes_nfs/$nodename/$folder");			
			`sed -i '/$nodename:\\/$folder/d' /etc/fstab`;
			`echo $nodename:/$folder /mnt/nodes_nfs/$nodename/$folder $mount_setting >> /etc/fstab`;
		}
		else{
			system("umount -l $nodename:/mnt/$folder"); 
			system("mkdir -p /mnt/nodes_nfs/$nodename/$folder");			
			`sed -i '/$nodename:\\/mnt\\/$folder/d' /etc/fstab`;
			`echo $nodename:/mnt/$folder /mnt/nodes_nfs/$nodename/$folder $mount_setting >> /etc/fstab`;
		}		
	}	
}

`sed -i '/^\$/d' /etc/fstab`;#remove blank lines
if(!`grep 'mount -a' /etc/rc.local`){
`echo mount -a >> /etc/rc.local`;}

if(!`grep 'setsebool -P use_nfs_home_dirs 1' /etc/rc.local`){
	`echo 'setsebool -P use_nfs_home_dirs 1' >> /etc/rc.local`;}
	
`setsebool -P use_nfs_home_dirs 1`;
system("mount -a");	
system("df -h > ./NFSnodes4server_mount.out");	
system("cat ./NFSnodes4server_mount.out");
# end of nfs
