#!/usr/bin/perl
#SLURM+ PMIx installation script developed by Prof. Shin-Pon Ju 2020/11/12
#!!!!!!!!!!! if you use different pmix version or 
# put them in different dir, you need to modify 06slurm_slave.pl in ForNode

# You need to install munge for server and nodes first
#slurm default installation path:
#/usr/local
#/usr/local/etc
#/root/slurm/slurm-19.05.4/etc/slurmctld.service
#/root/slurm/slurm-19.05.4/etc/slurmd.service
#/etc/systemd/system/
# cp /root/slurm/slurm-19.05.4/etc/slurmd.service /etc/systemd/system/
#cp /root/slurm/slurm-19.05.4/etc/slurmctld.service /etc/systemd/system/
#systemctl daemon-reload
#/etc/ld.so.conf: add /usr/local/lib/ , then ldconfig # for mpiexec

### for new nodes, you must modify IP_node
use warnings;
use strict;
use Expect;
use Parallel::ForkManager;
use MCE::Shared;
use Cwd; #Find Current Path

my $wgetORgit = "yes";

# find all threads to make this package
my $thread4make = `lscpu|grep "^CPU(s):" | sed 's/^CPU(s): *//g'`;
chomp $thread4make;
print "Total threads can be used for make: $thread4make\n";
if($thread4make == 0){die "thread Number for make is $thread4make\n";}

my $current_path = getcwd();# get the current path dir

my $expectT = 10;# time peroid for expect

my $packageDir = "/home/packages";
if(!-e $packageDir){# if no /home/packages, make this folder	
	system("mkdir $packageDir");	
}

## get available IPs by reading or find them by ssh
open my $ss,"< ./Nodes_IP.dat" or die "No Nodes_IP.dat to read"; 
my @temp_array=<$ss>;
my @avaIP=grep (($_!~m{^\s*$|^#}),@temp_array); # remove blank lines and comment lines
close $ss;
 
for (@avaIP){
	$_  =~ s/^\s+|\s+$//;
	chomp;
	print "IP: $_\n";
}

for (@avaIP){	
		$_ =~/192.168.0.(\d{1,3})/;#192.168.0.X
		my $temp= $1 - 1;
		my $nodeindex=sprintf("%02d",$temp);
		my $nodename= "node"."$nodeindex";
		chomp $nodename;
		#print "**nodename**:$nodename\n";
		unlink "/home/slurmDone_$nodename.txt";
}

my $forkNo = @avaIP;
my $pm = Parallel::ForkManager->new("$forkNo");

##!!!!!!!!! begin PMIx installation (not used currently)
#`dnf install -y libevent-devel`;# for pmix
#my $pmix_buildPath = "$packageDir/pmix/3.1";#v3.2 is the latest one, but not work with slurm so far
#my $pmix_installPath = "/opt/pmix/3.1";
#system("rm -rf $pmix_buildPath");
#system("rm -rf $pmix_installPath");
#system("mkdir -p $pmix_buildPath $pmix_installPath");
#chdir("$pmix_buildPath");
#system("git clone https://github.com/pmix/pmix.git source");
#if($?){die "git clone pmix fail!!\nReason:?!\n";}
#chdir("$pmix_buildPath/source") or die "no $pmix_buildPath/source folder\n";
#system("git branch -a");
#if($?){die "git branch -a failed!\nReason:?!\n";}
#system("git checkout v3.1");
#if($?){die "git checkout failed!\nReason:?!\n";}
#system("git pull");
#if($?){die "git pull failed!\nReason:?!\n";}
#system("perl ./autogen.sh");
#if($?){die "perl ./autogen.sh failed!!\nReason:?!\n";}
#system("./configure --prefix=$pmix_installPath");
#if($?){die "configure pmix failed!!\nReason:?!\n";}s
#system("make clean");
#system("make all -j $thread4make");
#if($?){die "make pmix failed!!!\n";}
#system("make install");
#if($?){die "make install pmix failed!!!\n";}
##
##die "Check pmix installation status\n";
###!!!!!!!!!! end of PMIx installation
#=b

system("dnf install -y chrony");#time sync
system("systemctl start chronyd");#time sync
system("systemctl enable chronyd");#time sync
system("timedatectl set-timezone Asia/Taipei");## setting timezone
#=big


# stop old slurm, if installed
system("systemctl stop slurmctld.service");
system("systemctl stop slurmd.service");
system("dnf remove slurm*");# if you use rpm to install before
#install Slurms
my $currentVer = "slurm-20.11.7.tar.bz2";#***** the latest version of this package (check the latest one if possible)
my $unzipFolder = "slurm-20.11.7";#***** the latest version of this package (check the latest one if possible)
my $URL = "https://download.schedmd.com/slurm/$currentVer";#url to download
my $Dir4download = "$packageDir/slurm_download"; #the directory we download slurm source code
my $buildPath = "/root/slurm";# the path to configure, make, and install slurm

#uninstall old one and remove old files
chdir("$buildPath/$unzipFolder");
system("make uninstall");
system("rm -f /var/log/slurmctld.log");
system("rm -f /var/log/slurm_jobacct.log");
system("rm -f /var/log/slurm_jobcomp.log");

system(	"rm -f /var/run/slurmd.pid");
system(	"rm -f /var/run/slurmctld.pid");
system("rm -f /var/log/slurmd.log");
system("rm -rf /var/spool/slurmd");
system("rm -rf /var/spool/slurmctld");
chdir($current_path);
#
#=big
#Begin downloading and install process
if($wgetORgit eq "yes"){
	system ("rm -rf $Dir4download");# remove the older directory first
	system("mkdir $Dir4download");# make a new directory for NFS (because the package is needed for each node)
	
	chdir("$Dir4download");
	system("wget  $URL");
	
	system("rm -rf $buildPath");# remove old one
	system("mkdir $buildPath");# make a new one
	system("cp $currentVer $buildPath");# make a new one
	sleep(3);
	chdir($current_path);
}
#die "uninstall check\n";
######## begin install slurm in each node (need fork in the future)
print "**** Install slurm for each node\n";
for (@avaIP){		
	sleep(2);
	$pm->start and next;
	print "***$_ is doing scp\n";
    system("scp ../ForNode/06slurm_slave.pl root\@$_:/root");
    my $exp = Expect->new;
	$exp = Expect->spawn("ssh -l root $_ \n");	
	$exp->send ("rm -f nohup.out\n") if ($exp->expect($expectT,'#'));
	$exp->send ("nohup perl ./06slurm_slave.pl &\n") if ($exp->expect($expectT,'#'));
	#$exp -> send("\n") if ($exp->expect($expectT,'#'));
	$exp -> send("exit\n") if ($exp->expect($expectT,'#'));
	$exp->soft_close();
	$pm->finish;
	sleep(2);
} # end of loop
$pm->wait_all_children;

#die "check nohup";
## slurm server installation

my @slurm_pack = qw(rpm-build openssl openssl-devel pam-devel numactl numactl-devel hwloc hwloc-devel lua lua-devel readline-devel 
rrdtool-devel bzip2-devel zlib-devel ncurses-devel fribidi man2html libibmad libibumad perl-ExtUtils-MakeMaker perl-DBI  perl-DBD-SQLite
wget python3 gtk*);

for (@slurm_pack){
	system("dnf -y install $_");
	if($?){die "Installation of $_ package failed (08slurm_server.pl)\n";}
}
system ("dnf upgrade -y");
system("ln -s /usr/bin/python3 /usr/bin/python");# for slurm configure process

chdir("$buildPath");
system ("tar -xjf $currentVer");#UNZIP bz2 file
if($?){die "tar -xjf $currentVer failed!\n";}
chdir($current_path);

chdir("$buildPath/$unzipFolder");
#system("./configure --with-pmix=$pmix_installPath |tee 00slurm_configureCheck.txt");
system("./configure");
if($?){die "slurm configure failed!!\nReason:?!\n";}
system("make clean");
system("make -j $thread4make");
if($?){die "slurm make failed!!\nReason:?!\n";}
system("make install");
if($?){die "slurm make install failed!!\nReason:?!\n";}
chdir($current_path);

#make pmi2 lib
chdir("$buildPath/$unzipFolder/contribs/pmi2");
system("make -j $thread4make");
if($?){die "pmi2 lib make failed!!\nReason:?!\n";}
system("make install");
if($?){die "pmi2 lib make install failed!!\nReason:?!\n";}
chdir($current_path);

#die "Check slurm installation status";
# slurm server setting
system("rm -f /etc/systemd/system/slurmd.service");
system("rm -f /etc/systemd/system/slurmdbd.service");
system("rm -f /etc/systemd/system/slurmctld.service");
system("cp /root/slurm/$unzipFolder/etc/slurmd.service /etc/systemd/system/");
if($?){die "cp slurmd.service failed!!\nReason:?!\n";}
system("cp /root/slurm/$unzipFolder/etc/slurmdbd.service /etc/systemd/system/");
if($?){die "cp slurmdbd.service failed!!\nReason:?!\n";}
system("cp /root/slurm/$unzipFolder/etc/slurmctld.service /etc/systemd/system/");
if($?){die "cp slurmctld.service failed!!\nReason:?!\n";}
system("systemctl daemon-reload");
if($?){die "systemctl daemon-reload failed!!\nReason:?!\n";}
#=cut
##configure slurm
#chdir($current_path);
tie my %coreNo, 'MCE::Shared';
tie my %socketNo, 'MCE::Shared';
tie my %threadcoreNo, 'MCE::Shared';
tie my %coresocketNo, 'MCE::Shared';
tie my %numaNo, 'MCE::Shared';

for (@avaIP){	
	$pm->start and next;
	my $exp = Expect->new;
	$exp = Expect->spawn("ssh -l root $_ \n");	
# get CPU Number	
	$exp->send ("lscpu|grep \"^CPU(s):\" | sed 's/^CPU(s): *//g' \n") if ($exp->expect($expectT,'#'));
	$exp->expect($expectT,'-re','\d+');#before() keeps command, match() keeps number, after() keep left part+root@master#
	my $Mread = $exp->match();
	chomp $Mread;
    if ($Mread){
	  $coreNo{$_} = $Mread;
	  print "coreNo hash array $_ , Mread: $Mread, $coreNo{$_}\n";
	  };
	  
# get socket Number	
	$exp->send ("lscpu|grep \"^Socket(s):\" | sed 's/^Socket(s): *//g' \n") if ($exp->expect($expectT,'#'));
	$exp->expect($expectT,'-re','\d+');#before() keeps command, match() keeps number, after() keep left part+root@master#
	$Mread = $exp->match();
	chomp $Mread;
    if ($Mread){
	  $socketNo{$_} = $Mread;
	  print "socketNo hash array $_ , Mread: $Mread, $socketNo{$_}\n";
	  };
 # get the thread Number per core 	
	$exp->send ("lscpu|grep \"^Thread(s) per core:\" | sed 's/^Thread(s) per core: *//g' \n") if ($exp->expect($expectT,'#'));
	$exp->expect($expectT,'-re','\d+');#before() keeps command, match() keeps number, after() keep left part+root@master#
	$Mread = $exp->match();
	chomp $Mread;
    if ($Mread){
	  $threadcoreNo{$_} = $Mread;
	  print "threadcoreNo hash array $_ , Mread: $Mread, $threadcoreNo{$_}\n";
	  };

# get the core Number per socket 	
	$exp->send ("lscpu|grep \"^Core(s) per socket:\" | sed 's/^Core(s) per socket: *//g' \n") if ($exp->expect($expectT,'#'));
	$exp->expect($expectT,'-re','\d+');#before() keeps command, match() keeps number, after() keep left part+root@master#
	$Mread = $exp->match();
	chomp $Mread;
    if ($Mread){
	  $coresocketNo{$_} = $Mread;
	  print "coresocketNo hash array $_ , Mread: $Mread, $coresocketNo{$_}\n";
	  };
# get the NUMA Number (slurm uses it as socket number)	
	$exp->send ("lscpu|grep \"^NUMA node(s):\" | sed 's/^NUMA node(s): *//g' \n") if ($exp->expect($expectT,'#'));
	$exp->expect($expectT,'-re','\d+');#before() keeps command, match() keeps number, after() keep left part+root@master#
	$Mread = $exp->match();
	chomp $Mread;
    if ($Mread){
	  $numaNo{$_} = $Mread;
	  print "numaNo hash array $_ , Mread: $Mread, $numaNo{$_}\n";
	  };
	  
	$exp -> send("exit\n") if ($exp->expect($expectT,'#'));
	$exp->soft_close();
	$pm->finish;
} # end of loop
$pm->wait_all_children;
sleep(1);
unlink "./IP_coreNo.txt";
open my $ss3,">./IP_coreNo.txt" or die "Can't open IP_coreNo.txt\n Reason:$!\n";
print $ss3 "IP  CoreNo SocketNo ThreadPerCore CorePerSocket NUMAnodeNo\n";
for (sort keys %coreNo){
	print $ss3 "$_  $coreNo{$_} $socketNo{$_} $threadcoreNo{$_} $coresocketNo{$_} $numaNo{$_}\n";
	print  "$_  $coreNo{$_} $socketNo{$_} $threadcoreNo{$_} $coresocketNo{$_} $numaNo{$_}\n";
}
close($ss3);

## check slurm installation status of each node
my $nodeNo = @avaIP;
my $whileCounter = 0;
my $slurmCounter = 50;
while ($slurmCounter != $nodeNo){
	$whileCounter += 1;
	$slurmCounter = 0;

	for (@avaIP){	
		$_ =~/192.168.0.(\d{1,3})/;#192.168.0.X
		my $temp= $1 - 1;
		my $nodeindex=sprintf("%02d",$temp);
		my $nodename= "node"."$nodeindex";
		#print "**nodename**:$nodename\n";
		if( -e "/home/slurmDone_$nodename.txt"){
			$slurmCounter += 1;			
			print "$nodename: Done!!!\n";
		}
		else{
			print "$nodename: slurm installation hasn't done\n";
		}		 
	}
	print "\n\n****Doing while times: $whileCounter\n";
	print "total node number need slurm to install: $nodeNo\n";
	print "Current node number with slurm installed: $slurmCounter\n\n";
	sleep(20);
}

system("chmod -R 755 $packageDir");
print "*********If slurm installation is done,You need to configure slurm now!!\n";
#srun --mpi=list
