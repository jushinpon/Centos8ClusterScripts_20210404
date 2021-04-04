=beg
This Perl script uses the Expect module to do the ssh command and some shell commands 
in the remote machine-- developed by Prof. Shin-Pon Ju at NSYSU (11/11/2019)
=cut

#!/usr/bin/perl
use Expect;
use Parallel::ForkManager;
$ganglia_user="root";
$ganglia_passwd="mem4268";
$expectT = 20;# time peroid for expect
$forkNo = 30;
#rrdtool，循環數據庫，是一種用於使用圖表存儲和顯示數據隨時間變化的工具。
#ganglia-gmetad是從您要監視的主機收集監視數據的守護程序。在這些主機和主節點中，還需要安裝ganglia-gmond（監視守護程序本身）。
#ganglia-web 提供Web前端，我們將在其中查看有關受監控系統的歷史圖表和數據。
system("yum -y install httpd ganglia rrdtool ganglia-gmetad ganglia-gmond ganglia-web");
$exp = Expect->new;
#為Ganglia Web界面（/usr/share/ganglia）設置身份驗證。我們將使用Apache提供的基本身份驗證。這裡設為root。
$exp = Expect->spawn("htpasswd -c /etc/httpd/auth.basic $ganglia_user");
$exp->expect(5, ['New password:',
				sub {
						my $self = shift ;
						$self->send("$ganglia_passwd\n");	
						#print "1:$ganglia_passwd";
						exp_continue;
					}
				],
                ['Re-type new password:',
				sub {
						my $self = shift;
						$self ->send("$ganglia_passwd\n");
						#print "2:$ganglia_passwd";
						exp_continue;
					}
				] 
			);
$exp->soft_close();
#修改/etc/httpd/conf.d/ganglia.conf 
`echo Alias /ganglia /usr/share/ganglia > /etc/httpd/conf.d/ganglia.conf`;
`echo '<Location /ganglia>' >> /etc/httpd/conf.d/ganglia.conf`;
`echo AuthType basic >> /etc/httpd/conf.d/ganglia.conf`;
`echo 'AuthName \"Ganglia web UI\"' >> /etc/httpd/conf.d/ganglia.conf`;
`echo AuthBasicProvider file >> /etc/httpd/conf.d/ganglia.conf`;
`echo 'AuthUserFile \"/etc/httpd/auth.basic\"' >> /etc/httpd/conf.d/ganglia.conf`;
`echo Require user $ganglia_user >> /etc/httpd/conf.d/ganglia.conf`;
`echo '</Location>' >> /etc/httpd/conf.d/ganglia.conf`;
#system("cat /etc/httpd/conf.d/ganglia.conf");
#修改/etc/ganglia/gmetad.conf
@IP =`netstat -ntu | grep ESTAB | awk '{print $4}' | cut -d: -f1 | sort | uniq -c | sort -nr`;
foreach (@IP)
{
	if ($_ =~ /\s+\d+\s+(140\.\d+\.\d+\.(\d+))/)
	{
		$severIP=$1;     
		$severIP2=$2;     
	}
	if ($_ =~ /\d+ tcp.+192.168.0.(\d+)/)
	{
		$node_number=$1-1;     
	}
}
`echo gridname "$severIP2" > /etc/ganglia/gmetad.conf`;
`echo setuid_username ganglia >> /etc/ganglia/gmetad.conf`;
`echo case_sensitive_hostnames 0 >> /etc/ganglia/gmetad.conf`;
open ss,"</etc/hosts";
@avaIP=<ss>;# all available IPs
close ss;
foreach(@avaIP)
{
	if ($_ =~ /(192.168.0.\d+)\s+(\S+)/)
	{
		$nodeip=$1;     
		$nodename=$2;
		if ($nodename =~ master)
		{
			`echo data_source "$nodename" 10 $nodeip:8649 >> /etc/ganglia/gmetad.conf`;
		}
		else
		{
			`echo data_source "$nodename" 10 $nodeip >> /etc/ganglia/gmetad.conf`;
			push(@nodetable,"$nodename\n");
		}	     
	}
}
#system("cat /etc/ganglia/gmetad.conf");
#修改/etc/ganglia/gmond.conf
system("cp /etc/ganglia/gmond.conf /etc/ganglia/gmond.conf.bak");
open ss,"</etc/ganglia/gmond.conf";
@gmond=<ss>;# all available IPs
close ss;
open ss1,">/etc/ganglia/gmond.conf";
foreach(@gmond)
{
	if ($_ =~ /^\s+name \= \"unspecified\"/)
	{
		$_ =~ s/\"unspecified\"/\"master\"/;
		#print $_;
	}
	if ($_ =~ /^\s+mcast\_join \= 239\.2\.11\.71/)
	{
		$_ =~ s/mcast_join/#mcast_join/;
	}
	if ($_ =~ /^\s+bind \= 239\.2\.11\.71/)
	{
		$_ =~ s/bind/#bind/;
	}
	print ss1 "$_";
}
close ss1;
#system("cat /etc/ganglia/gmond.conf");
#system("cp /etc/ganglia/gmond.conf.bak /etc/ganglia/gmond.conf");
#system("y\n");
system("iptables -A INPUT -p tcp --dport 6489 -j ACCEPT");
`iptables-save >  /etc/sysconfig/iptables`;
system("systemctl restart httpd gmetad gmond");
system("systemctl enable httpd gmetad gmond");

#FOR NODE
my $pm = Parallel::ForkManager->new("$forkNo");
#@nodetable=qw/node01/;
foreach (@nodetable)
{
	$pm->start and next;
	$nodename=$_;
	chomp $nodename;
	print "**nodename**:$nodename\n";
	system("ssh $nodename \'rm -rf /root/00pack_ganglia_node.pl\'");
	system("scp /root/00pack_ganglia_node.pl root\@$nodename:/root");
	system("ssh $nodename \'rm -rf nohup.out\'");
    $exp = Expect->new;
	$exp = Expect->spawn("ssh $nodename\n");
	$exp->send("nohup perl 00pack_ganglia_node.pl & \n") if ($exp->expect($expectT,'#'));# nohup perl can't be done by ssh nodeXX ''
	$exp->send("exit\n") if ($exp->expect($expectT,'#'));
	$exp->soft_close();
    $pm-> finish;
}
$pm->wait_all_children;