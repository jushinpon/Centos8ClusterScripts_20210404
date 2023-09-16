# shutdown for all nodes by using at
#at examples:
#MM/DD/YY
#echo "/usr/bin/perl '/root/Centos8ClusterScripts_20210404/shutdown4all.pl' > ~/at_shutdown.txt" |at 6:30 AM 07/24/2022
#echo "/usr/bin/perl '/root/Centos8ClusterScripts_20210404/shutdown4all.pl' > ~/at_shutdown.txt" | at now +1 minute
#echo "rsync -av /home/tux me@myserver:/home/tux/" | at 3:30 AM tomorrow 
#echo "/opt/batch.sh ~/Pictures" | at 3:30 AM 08/01/2022 
#echo "echo hello" | at now + 3 days
#% at 8pm Aug 31
#at> echo hello
#at> <EOT>
#job 161 at Sat Aug 31 20:00:00 2019
#/usr/sbin/poweroff

use Parallel::ForkManager;
$forkNo = 100;
my $pm = Parallel::ForkManager->new("$forkNo");
my $server = "yes";#have server to shutdown or not
my %nodes = (
    161 => [1..42],#1,3,39..
    182 => [1..24],
    186 => [1..7],
    190 => [1..3],
    195 => [1..7]
    );
chomp @ARGV;    
#my $what2do = "$ARGV[0]";
my $what2do = "echo \'shutdown -h now\' | at 7:50 AM today";
#print "$ARGV[0]\n";
#die;
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

for (@nodes){
$pm->start and next;
    $nodeindex=sprintf("%02d",$_);
    $nodename= "node"."$nodeindex";
    print "$nodename\n";
    $cmd = "ssh $nodename ";
    #`$cmd "shutdown -h now"`;
    #`$cmd "$what2do"`;
    system("$cmd \"$what2do\"");
$pm->finish;
}
$pm->wait_all_children;

my $dat = `/usr/bin/date`;
chomp $dat;
print "$what2do for all nodes at $dat\n";
sleep(3);
if($server eq "yes"){
    print "server action for $what2do\n";
    `$what2do`;
}