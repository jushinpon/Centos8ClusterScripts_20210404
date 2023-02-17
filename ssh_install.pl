# ssh nodeXXX test 
#nohup /opt/memtest/bin/memtester 30176 10 &
#nohup ifdown enp1s0 down && ifup enp1s0 up &

use Parallel::ForkManager;
$forkNo = 100;
my $pm = Parallel::ForkManager->new("$forkNo");
#$reboot_check = "yes";

my %nodes = (
    #161 => [33..38],#1,3,39..
    161 => [1..42],#1,3,39..
   # 182 => [24],
    182 => [1..4,6..15,17..24],
    186 => [1..7]
    );

my $ip = `/usr/sbin/ip a`;    
$ip =~ /140\.117\.\d+\.(\d+)/;
my $cluster = $1;
$cluster =~ s/^\s+|\s+$//;
#print "\$cluster: $cluster\n";
my @allnodes = @{$nodes{$cluster}};#get node information

`/usr/bin/touch ./scptest.dat`;
my @nodes;

for (@allnodes){
  my  $nodeindex=sprintf("%02d",$_);
  my  $nodename= "node"."$nodeindex";
    chomp $nodename;
    print "****Check $nodename status\n ";
    #`echo "***$nodename" >> $output`;
#use scp for ssh test
	system("scp -o ConnectTimeout=5 ./scptest.dat root\@$nodename:/root");    
    if($?){
		print "scp at $nodename failed\n";
		next;
		}
	else{
		print "scp at $nodename ok for ssh test\n";
        push @nodes,$_;
		}	
    
}

# status check
my $hundredM = 100*1024*1024/4096;

#for reconfigure
#`cp /root/Centos8ClusterScripts_20210404/Server/slurm.conf /usr/local/etc/`; # for slurm reconfigure
##`cp /root/Centos8ClusterScripts_20210404/Server/gres.conf /usr/local/etc/`; # for slurm reconfigure
#`systemctl restart slurmctld`; # for slurm reconfigure
#`systemctl restart slurmd`; # for slurm reconfigure
#`rm -f check.txt`;
#`touch check.txt`;

#print "\@nodes: @nodes\n";

#unlink "./memoryInfo.dat";
#`touch ./memoryInfo.dat`;

#unlink "./release.dat";
#`touch ./release.dat`;
system("cp ./slurm_rotate.txt /etc/logrotate.d/slurm");
for (@nodes){
#$pm->start and next;
    $nodeindex=sprintf("%02d",$_);
    $nodename= "node"."$nodeindex";
    print "$nodename\n";
    $cmd = "ssh $nodename ";
#slurm log rotate
  `scp  ./slurm_rotate.txt root\@$nodename:/etc/logrotate.d/slurm`;
  # `$cmd "poweroff"`;

#    my $OS = `$cmd "cat /etc/redhat-release"`;
#    chomp $OS;
#   # print "\$OS: $OS";
#   # if($OS){
#        `echo "$nodename:" >> ./release.dat`;
#            `echo "$OS" >> ./release.dat`;
#        `echo "**********" >> ./release.dat`;
#   # }
 #remove swap
   # my $swap_dev = `$cmd "blkid|grep swap|awk '{print \\\$1}'"`;
   # $swap_dev =~ tr/://d;
   # chomp $swap_dev;
   # print "\$swap_dev: $swap_dev\n";
   # system("$cmd 'sed -i -e \"s|$swap_dev|#$swap_dev|g\" /etc/fstab' ");
   # system("$cmd 'sed -i -e \"s|/swap/swap|#/swap/swap|g\" /etc/fstab' ");
   # system("$cmd 'swapoff -a' ");
   # system("$cmd 'rm -rf /swap' ");
   # system("$cmd 'free -h' ");

#   # if($OS){
#        `echo "$nodename:" >> ./release.dat`;
#            `echo "$OS" >> ./release.dat`;
#        `echo "**********" >> ./release.dat`;
#   # }

  
  #  my @ram = `$cmd "lshw -C memory -short"`;
  #  chomp @ram;
  #  `echo "$nodename:" >> ./memoryInfo.dat`;
  #  for my $m (@ram){
  #      `echo "$m" >> ./memoryInfo.dat`;
  #  }
  #  `echo "**********" >> ./memoryInfo.dat`;


# modify repository source url
# Maximum Capacity: 32 GB
#Number Of Devices: 4

    #system("$cmd 'sed -i -e \"s|mirrorlist=|#mirrorlist=|g\" /etc/yum.repos.d/CentOS-*' ");
	#system("$cmd 'sed -i -e \"s|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g\" /etc/yum.repos.d/CentOS-*'");
	#system("$cmd 'dnf clean all'");
	#system("$cmd 'dnf update -y'");
#sed -i -e "s|mirrorlist=|#mirrorlist=|g" /etc/yum.repos.d/CentOS-*
#[root@node28 ~]# sed -i -e "s|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g" /etc/yum.repos.d/CentOS-*
#    `$cmd "reboot"`;
#slurm.conf
   # `scp  /usr/local/etc/slurm.conf root\@$nodename:/usr/local/etc/`;
   # system("scp  /usr/local/etc/slurm.conf root\@$nodename:/usr/local/etc/");
   # `$cmd "systemctl restart slurmd"`; # for slurm reconfigure
#    #gres.conf
#    `scp  /usr/local/etc/gres.conf root\@$nodename:/usr/local/etc/`;
#    `$cmd "systemctl restart slurmd"`; # for slurm reconfigure
##ssh modify
   # `$cmd "sed -i '/StrictModes/d' /etc/ssh/sshd_config"`;#remove old setting first
   # `$cmd "sed -i '\\\$ a StrictModes no' /etc/ssh/sshd_config"`;# $ a for sed appending
   # `$cmd "systemctl restart sshd"`;# $ a for sed appending

    #print "\n****Check $nodename status\n ";
    #system("ping -c 1 $nodename");
    #if($?){`echo '$nodename ping failed!' >> check.txt`;}
     #   system("$cmd 'systemctl stop dnf-makecache.timer'");
     #   system("$cmd 'systemctl disable dnf-makecache.timer'");
        #my $df  = `$cmd 'free -h'`;
        #my $df  = `$cmd 'df -h /swap'`;
       # chomp $df;
       # print "$nodename\n";
       # print "$df\n";
        #system("$cmd 'df -h /swap'");

##modify swap for each node    
#    unless($?){
#        my $df = `$cmd 'df /swap|grep swap|awk "{print \\\$4}"'`;
#        chomp $df;
#        print "$nodename \n";
#        `$cmd 'rm -f /swap/*'`;
#        `$cmd 'dd if=/dev/zero of=/swap/swap bs=1024 count=$df'`;
#        system("$cmd 'chmod 0644 /swap/swap'");
#        `$cmd 'mkswap -f /swap/swap'`;
#        `$cmd 'swapon /swap/swap'`;
#        system("$cmd 'sed -i \"/swap/d\" /etc/fstab'");
#        system("$cmd 'sed -i \"\\\$ a /swap/swap swap swap defaults 0 0\" /etc/fstab'");
#        system("$cmd 'swapon -s'");
#        sleep(1);
#       # unless(`ssh $nodename "grep 'systemctl restart slurmd' /etc/rc.local"`){
#	   #     `ssh $nodename "echo 'systemctl restart slurmd' >> /etc/rc.local"`;
#       #     print "no restart slurmd in $nodename \n ";
#       # #`echo mount -a >> /etc/rc.local`;}
#       # }
#    }


##modify /etc/rc.loca for each node    
#    unless($?){
#        unless(`ssh $nodename "grep 'systemctl restart slurmd' /etc/rc.local"`){
#	        `ssh $nodename "echo 'systemctl restart slurmd' >> /etc/rc.local"`;
#            print "no restart slurmd in $nodename \n ";
#        #`echo mount -a >> /etc/rc.local`;}
#        }
#    }


        #system("$cmd 'dnf install -y perl* --nobest --skip-broken'");
        #system("$cmd 'echo \'yes\'|cpan App::cpanminus'");
        #system("$cmd 'cpanm Env::Modify --force'");
        #system("$cmd 'cpanm Parallel::ForkManager --force'");
        #system("$cmd 'cpanm Expect --force'");
        #system("$cmd 'cpanm Statistics::Descriptive --force'");
        #sleep(1);
        #system("$cmd 'dnf install -y perl-MCE-Shared'");    
    # 

        #my @ps= `$cmd "ps aux|grep -v grep|grep -v root|grep 1009"`;#|awk '{print \\\$2}'|xargs kill" `;
        #print "@ps\n";

#    }
    #system("$cmd 'systemctl restart slurmd'");

    #system("$cmd 'rm -f nohup.out'");
    #system("$cmd 'nohup perl 06slurm_slave.pl &'");
    #system("$cmd 'nohup perl 06slurm_slave.pl &'");
    #if($?){print "$?: $nodename is dead. $!\n"}
#get remote files   
 # my @remote = `$cmd 'ls /etc/sysconfig/network-scripts/*'`;
 # print "@remote\n";
 # for my $if (@remote){
 #   chomp $if;
 #   $if =~ /ifcfg-(.+)/;
 #   print "$1\n";
 #   chomp $1;
 #   system("$cmd 'sed -i \"/MTU/d\" $if'");
 #   system("$cmd 'sed -i \"\\\$ a MTU=1500\" $if'");
 #   system("$cmd 'ifconfig $1 mtu 1500'");
 # }  
    #for my $disk (@{$partedDevs{$nodename}}){
    #    chomp $disk;
    #    print "/dev/$disk\n";
    #    system("$cmd 'tune2fs -r $hundredM /dev/$disk'");#nis for nodes    
	#
    #}
    #tune2fs -r $((100*1024*1024/4096)) /dev/sdb1
#restart nis    
  #system("$cmd 'systemctl restart rpcbind ypbind nis-domainname oddjobd'");#nis for nodes    
  #system("$cmd 'yptest'"); 
      
  #system("$cmd 'reboot'"); 
  #system("$cmd 'mount -a'"); 
     
# check disk for each nodes        
    #system("$cmd 'df -h'");    
    #system("$cmd 'blkid'");    
    #system("$cmd 'rpm -qa| grep parted'");
    #if not -> dnf install parted -y 
    #
    #system("$cmd 'dnf install -y perl*'");    
    #system("$cmd 'dnf install -y perl-Parallel-ForkManager'");    
    #system("$cmd 'chown -R jsp: /free'");    
#$pm->finish;
}
#$pm->wait_all_children;

print "Maybe you need to do scontrol reconfigure\n";
#my $slurmdown = `sinfo|grep All|grep down|awk '{print \$NF}'`;
#chomp ($slurmdown);
#`scontrol update nodename=$slurmdown state=resume` if($slurmdown);
#system("sinfo");

die;


for (1..7){
    #$pm->start and next;
    $nodeindex=sprintf("%02d",$_);
    $nodename= "node"."$nodeindex";
    print "****nodename: $nodename\n";
    $cmd = "ssh $nodename ";
    ##infiniband driver, reboot is needed.
    #system("$cmd 'yum install -y ntfs-3g'");
    #system("$cmd 'systemctl restart rpcbind ypbind nis-domainname oddjobd'");#nis for nodes
    system("$cmd 'poweroff'");#nis for nodes
    print "\n****$nodename\n";
    system("$cmd 'df -h'|grep free");
    #my $temp = `$cmd 'df -h'|grep free`;
    #print "$temp\n";
    #if($temp =~ m{free}){print "$1\n"}
    #system("$cmd 'systemctl restart rpcbind ypbind nis-domainname oddjobd'");#nis for nodes
    #system("$cmd 'rm -f nohup.out;nohup perl ./06slurm_slave.pl &'");
    #system("$cmd 'dnf install -y iftop'");
    system("$cmd 'mount -a'");
    system("$cmd 'systemctl restart slurmd'");
    #system("$cmd 'dnf -y group install \"Development Tools\"'");
    
    # install progress
    #system("$cmd 'dnf install perl-Statistics-Descriptive -y;'");
    
    ##perl module
    
    #system("$cmd 'dnf install perl-Statistics-Descriptive -y'");
    #print "Check $nodename status\n ";
    #system("$cmd 'ibv_devinfo'");    
    #$pm->finish;
}
#$pm->wait_all_children;

die;
### check the node status after reboot
#if($reboot_check eq "yes"){
#	print "Sleep awhile (30 sec.) for checking reboot status\n";
#	sleep(30); 
#	for (1..3){
#		$nodeindex=sprintf("%02d",$_);
#		$nodename= "node"."$nodeindex";
#		system("ping -c 3 $nodename");
#		if($?){print "reboot for $nodename hasn't done!!\n\n"}	
#	}
#}

#for (1..41){
#    #$pm->start and next;
#    $nodeindex=sprintf("%02d",$_);
#    $nodename= "node"."$nodeindex";
#    #system("ssh $nodename 'dnf install perl-Statistics-Descriptive -y'");
#    print "nodename:$nodename\n";
#    system("munge -n \| ssh $nodename unmunge");
#    if($!){sleep(3);}
#    #$pm->finish;
#}
#$pm->wait_all_children;

