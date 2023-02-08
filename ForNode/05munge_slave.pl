#!/usr/bin/perl
#SLURM slave installation script developed by Prof. Shin-Pon Ju 2019/12/15
use strict;
use warnings;

my $centVer= `cat /etc/redhat-release`;
$centVer =~ /release\s+(\d)\.\d+\.\d+.+/;
chomp $1;
my $currentVer = $1;
print "Centos Version: $currentVer\n";

if($currentVer eq "8"){
	system("sed -i -e \"s|mirrorlist=|#mirrorlist=|g\" /etc/yum.repos.d/CentOS-*");
	system("sed -i -e \"s|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g\" /etc/yum.repos.d/CentOS-*");
	system("dnf clean all");
}

system("yum install -y 'dnf-command(config-manager)'");
system("dnf install dnf-plugins-core -y");
system("dnf config-manager --set-enable powertools");
#Munge is an authentication tool used to identify messaging from the Slurm machines
my $hostname = `hostname`;
chomp $hostname;# need to chomp
my $hostfileDone = "/home/munge_$hostname.txt"; # show the slurm installation is done 
unlink ("$hostfileDone");

system("yum install yum-utils -y");
system("yum-complete-transaction --cleanup-only");
system("package-cleanup --dupes");
system("package-cleanup --problems");
system("yum install epel-release -y");
system("yum upgrade -y  --nobest --exclude=kernel*");

system("systemctl stop munge");
system("killall munged");

system("yum remove  munge munge-libs munge-devel -y");
sleep(1);

if(`grep 'slurm' /etc/passwd`){#remove the old slurm account
	system("userdel -r slurm");
}

if(`grep 'munge' /etc/passwd`){#remove the old slurm account
	print "**Response from grep 'munge' /etc/passwd: True \n";
	my $temp = `userdel -r munge`;
	print "**Response from userdel -r munge: $temp \n"; #empty is good
		if($temp=~/currently used by process (\d+)/){
			`kill $1`;
			`userdel -r munge`;
			}
}
### End of removing old slurm setting
=b
Create the global users:
Slurm and Munge require consistent UID and GID across every node in the cluster.
=cut

#For all the nodes, before you install Slurm or Munge:
my $MUNGEUSER=950;
`groupadd -g $MUNGEUSER munge`;
`useradd  -m -c "MUNGE Uid 'N' Gid Emporium" -d /var/lib/munge -u $MUNGEUSER -g munge  -s /sbin/nologin munge`;
my $SLURMUSER=951;
`groupadd -g $SLURMUSER slurm`;
`useradd  -m -c "SLURM workload manager" -d /var/lib/slurm -u $SLURMUSER -g slurm  -s /bin/bash slurm`;

#install Munge (for all nodes and server)
system("rm -rf /etc/munge");
system("rm -rf  /var/log/munge");
system("rm -rf  /var/lib/munge");

system("yum install munge munge-libs munge-devel -y");
sleep(2);
system("chown -R munge: /etc/munge/ /var/log/munge/");
system("chmod 0700 /etc/munge/ /var/log/munge/");
system("chmod 0711 /var/lib/munge/");

system("echo '!!!!!Munge installatoin done!!!'> $hostfileDone");
sleep(1);
system("echo 'ls check for munge dir in /etc/munge'>> $hostfileDone");
sleep(1);
system("ls -al /etc/munge >> $hostfileDone");
sleep(1);
print "*****munge installation done \n";

