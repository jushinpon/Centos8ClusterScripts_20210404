#!/usr/bin/perl
#SLURM+ PMIx installation for nodes, developed by Prof. Shin-Pon Ju 2020/11/12

use warnings;
use strict;
use Cwd; #Find Current Path

system("dnf install -y chrony");#time sync
system("systemctl start chronyd");#time sync
system("systemctl enable chronyd");#time sync
system("timedatectl set-timezone Asia/Taipei");## setting timezone


# find all threads to make this package
#my $thread4make = `lscpu|grep "^CPU(s):" | sed 's/^CPU(s): *//g'`;
my $thread4make = `nproc`;
chomp $thread4make;
print "Total threads can be used for make: $thread4make\n";
if($thread4make == 0){die "thread Number for make is $thread4make\n";}
my $hostname = `hostname`;
chomp $hostname;# need to chomp
my $hostfile = "/home/slurm_$hostname.txt"; # get the hostname for output file 
my $hostfileDone = "/home/slurmDone_$hostname.txt"; # show the slurm installation is done 
unlink ("$hostfile");
unlink ("$hostfileDone");

my $current_path = getcwd();# get the current path dir
my $packageDir = "/home/packages";
my $Dir4download = "$packageDir/slurm_download"; #the directory we download slurm source code
#my $pmix_installPath = "/opt/pmix/3.1";

# slurm for slave
my $currentVer = "slurm-22.05.7.tar.bz2";#***** the latest version of this package (check the latest one if possible)
#my $currentVer = "slurm-20.11.7.tar.bz2";#***** the latest version of this package (check the latest one if possible)
my $unzipFolder = "slurm-22.05.7";#***** the latest version of this package (check the latest one if possible)
#my $unzipFolder = "slurm-20.11.7";#***** the latest version of this package (check the latest one if possible)
my $buildPath = "/root/slurm";# the upper level path to configure, make, and install slurm

# stop old slurm, and uninstall slurm 
system("systemctl disable slurmd.service");
system("systemctl stop slurmd.service");
system("dnf remove slurm*");# if you use rpm to install before
chdir("$buildPath/$unzipFolder");
system("make uninstall");# if installation from scratch
system("rm -f /var/log/slurmctld.log");
system("rm -f /var/log/slurm_jobacct.log");
system("rm -f /var/log/slurm_jobcomp.log");

system(	"rm -f /var/run/slurmd.pid");
system(	"rm -f /var/run/slurmctld.pid");
system("rm -f /var/log/slurmd.log");
system("rm -rf /var/spool/slurmd");
system("rm -rf /var/spool/slurmctld");

system("rm -rf $buildPath");
system("mkdir $buildPath");
system("cp $Dir4download/$currentVer $buildPath");
if($?){die "No file to copy\n";}

my @slurm_pack = qw(openssl openssl-devel pam-devel numactl numactl-devel hwloc hwloc-devel lua lua-devel readline-devel 
rrdtool-devel bzip2-devel zlib-devel ncurses-devel fribidi man2html libibmad libibumad perl-ExtUtils-MakeMaker perl-DBI  perl-DBD-SQLite
wget python3);


for (@slurm_pack){
	system("dnf -y install $_");
	if($?){die "Installation of $_ package failed (08slurm_server.pl)\n";}
}
system ("dnf upgrade -y");
system("ln -s /usr/bin/python3 /usr/bin/python");# need python for configure process

#Begin the installation process

chdir("$buildPath");
system ("tar -xjf $currentVer");#UNZIP bz2 file
if($?){die "tar -xjf $currentVer failed!\n";}

chdir("$buildPath/$unzipFolder");
unlink "$hostfile";
#system("./configure --with-pmix=$pmix_installPath |tee $hostfile");
system("./configure |tee $hostfile");
if($?){die "slurm configure failed!!\nReason:?!\n";}
system("make clean");
`echo '!!!!!Begin make!!!'|tee -a $hostfile`;
system("make -j $thread4make|tee -a $hostfile");
if($?){die "slurm make failed!!\nReason:?!\n";}
`echo '!!!!!Begin make install!!!'|tee -a $hostfile`;
system("make install |tee -a $hostfile");
if($?){die "slurm make install failed!!\nReason:?!\n";}

#make pmi2 lib
chdir("$buildPath/$unzipFolder/contribs/pmi2");
system("make -j $thread4make");
if($?){die "pmi2 lib make failed!!\nReason:?!\n";}
system("make install");
if($?){die "pmi2 lib make install failed!!\nReason:?!\n";}

# slurm setting
system("rm -f /etc/systemd/system/slurmd.service");
system("cp /root/slurm/$unzipFolder/etc/slurmd.service /etc/systemd/system/");
if($?){die "cp slurmd.service failed!!\nReason:?!\n";}
system("systemctl daemon-reload");
if($?){die "systemctl daemon-reload failed!!\nReason:?!\n";}


`echo '!!!!!slurm installatoin done!!!'> $hostfileDone`;
`echo 'ls check for slurmd.service in /etc/systemd/system/slurmd.service'>> $hostfileDone`;
`ls -al /etc/systemd/system/slurmd.service >> $hostfileDone`;
#srun --mpi=list
