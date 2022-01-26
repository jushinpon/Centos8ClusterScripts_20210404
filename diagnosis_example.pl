# ssh nodeXXX test
#nohup ifdown enp1s0 down && ifup enp1s0 up &

use Parallel::ForkManager;
use Cwd;
#my $currentPath = getcwd();
$forkNo = 1;
my $pm = Parallel::ForkManager->new("$forkNo");
my $prefix = `/usr/bin/date +\%F-\%H`;
chomp $prefix;
my $output = "/root/$prefix"."_diagnosis.dat";
`/usr/bin/rm -f $output`;
`/usr/bin/touch $output`;
#`touch scptest.dat`;
#`dd if=/dev/zero of=scptest.dat bs=1024 count=10`;
#my
my @allnodes = (1..24);
my @badnodes = (28..31);
my @nodes;
for my $a (@allnodes){
    chomp $a;
    my $index = 1;	
    for my $b (@badnodes){
        chomp $b;
        $index = 0 if($a == $b);
    }
  push @nodes, $a  if($index == 1);
} 
 #slurmd and slurmctld check for master
    my @slurmd = `/usr/bin/systemctl status slurmctld|/usr/bin/egrep "inactive|failed"`;
    # print "@slurmd\n";
    if(@slurmd){
        `/usr/bin/echo "???slurmd is inactive or failed at master" >> $output`;
        `/usr/bin/echo "***doing restart slurmd and slurmctld for master" >> $output`;        
        `/usr/bin/systemctl restart slurmd`;
        `/usr/bin/systemctl restart slurmctld`;

        #check again
        @slurmd = `/usr/bin/systemctl status slurmd|/usr/bin/egrep "inactive|failed"`;        
        system("/usr/local/bin/scontrol update nodename=master state=resume");
        if(@slurmd){`/usr/bin/echo "???***slurmd still failed at master after restart slurmd!!!!" >> $output`;}
    }
    else{
        `/usr/bin/echo "slurmd is active at master" >> $output`;
    }
   
#my @nodes1 = "";
`/usr/bin/touch ~/scptest.dat`;
for (@nodes){
$pm->start and next;
	my $scontrol = 1;
    $nodeindex=sprintf("%02d",$_);
    $nodename= "node"."$nodeindex";
    $cmd = "/usr/bin/ssh $nodename ";
    print "****Check $nodename status\n ";
    #`echo "***$nodename" >> $output`;
#use scp for ssh test
	system("scp -o ConnectTimeout=5 ~/scptest.dat root\@$nodename:/root");    
    if($?){
		print "scp at $nodename failed\n";
		$scontrol = 0;
		next;
		}
	else{
		print "scp at $nodename ok for ssh test\n";
		}	
    
#ping test
    
    system("/usr/sbin/ping -c 1 $nodename");
    
    if($? ne 0){
        `/usr/bin/echo "" >> $output`;
        `/usr/bin/echo "??????ping failed at $nodename" >> $output`;
			$scontrol = 0;    
	}
    else{#ping ok
        `/usr/bin/echo "" >> $output`;        
        `/usr/bin/echo "******ping ok at $nodename" >> $output`;  
    #slurmd check
    my @slurmd = `$cmd '/usr/bin/systemctl status slurmd|/usr/bin/egrep "inactive|failed"'`;
    my $sinfo = `/usr/local/bin/sinfo -R|/usr/bin/grep $nodename`;# unexpectedly reboot, slurmd could be active, but resume is still needed. 
    print "@slurmd\n";
    if(@slurmd or $sinfo){
        `/usr/bin/echo "???slurmd is inactive or failed at $nodename" >> $output`;
        `/usr/bin/echo "***doing restart slurmd at $nodename" >> $output`;        
        `$cmd '/usr/bin/systemctl restart slurmd'`;

        #check again
        @slurmd = `$cmd '/usr/bin/systemctl status slurmd|/usr/bin/egrep "inactive|failed"'`;        
        system("/usr/local/bin/scontrol update nodename=$nodename state=resume");
        if(@slurmd){
			`/usr/bin/echo "???***slurmd still failed at $nodename after restart slurmd!!!!" >> $output`;
			$scontrol = 0;	
		}
    }
    else{
        `/usr/bin/echo "slurmd is active at $nodename" >> $output`;
    }
    #chomp $nodename;
    #unless($?){system("$cmd 'systemctl restart slurmd'");}
#

##scp test and remote cp test  
#    system("scp -o ConnectTimeout=10 scptest.dat root\@$nodename:/root");
#    if($?){`echo "scp failed at $nodename" >> $output`;}
#    system("$cmd 'cp scptest.dat /root/");
#    if($?){`echo "cp to root folder failed at $nodename" >> $output`;}
#
##nfs test
    my @mount = `$cmd '/usr/bin/mount|/usr/bin/grep nfs'`;
    chomp @mount;
    my @nfs = grep (($_=~m{master:/home|master:/opt}),@mount);
    my $nfsdiskNo = @nfs;
    #unless(@nfs){
    if($nfsdiskNo != 2){#home and opt
        `/usr/bin/echo "nfs failed at $nodename" >> $output`;
        `/usr/bin/echo "doing mount -a at $nodename" >> $output`;        
        `$cmd '/usr/bin/mount -a'`;
        #check again
        @mount = `$cmd '/usr/bin/mount|/usr/bin/grep nfs'`;
        @nfs = grep (($_=~m{master:/home|master:/opt}),@mount); 
        my $nfsdiskNo = @nfs;       
        if($nfsdiskNo != 2){
			`/usr/bin/echo "???***nfs still failed at $nodename after mount -a!!!!" >> $output`;
			$scontrol = 0;
		}
        
    }
    else{
        `/usr/bin/echo "nfs good at $nodename" >> $output`;
    }
##munge test
#    system("munge -n \| ssh $nodename unmunge");
#    if($?){`echo "munge failed at $nodename" >> $output`;} 

#swap test

    #system ("$cmd 'free'");
    my $swap = `$cmd '/usr/bin/free|/usr/bin/grep Swap:|/usr/bin/awk "{print \\\$2}"'`;
    chomp $swap;
    unless($swap){
        `$cmd '/usr/bin/rm -f /swap/*'`;
        `$cmd '/usr/bin/dd if=/dev/zero of=/swap/swap bs=1M count=4096'`;
        system("$cmd '/usr/bin/chmod 0644 /swap/swap'");
        `$cmd '/usr/sbin/mkswap -f /swap/swap'`;
        `$cmd '/usr/sbin/swapon /swap/swap'`;
        system("$cmd '/usr/sbin/swapon -s'");
    }#swap

    }# good ping loop
#if $scontrol still equals to 1
 if($scontrol){`/usr/local/bin/scontrol update nodename=$nodename state=resume`;}
   $pm->finish;
}
$pm->wait_all_children;

system("/usr/bin/grep ? $output > /root/currentBADnode.dat");#get lines with ? symbol for bad information
#my @sinfo = `/usr/local/bin/sinfo -R|/usr/bin/grep -v REASON|/usr/bin/awk '{print \$NF}'`;
#chomp (@sinfo);
#for (@sinfo){
#    `/usr/local/bin/scontrol update nodename=$_ state=resume`;
#}
print "\n\n****Final sinfo -R check****\n\n";
system("/usr/local/bin/sinfo -R");
