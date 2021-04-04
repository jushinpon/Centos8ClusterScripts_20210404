#FOR NODE
@IP =`netstat -ntu | grep ESTAB | awk '{print $4}' | cut -d: -f1 | sort | uniq -c | sort -nr`;
foreach (@IP)
{
	if ($_ =~ /\s+\d+\s+(140\.\d+\.\d+\.(\d+))/)
	{
		$severIP=$1;     
		$severIP2=$2;     
	}
	if ($_ =~ /\s+\d+\s+192.168.0.(\d+)/)
	{
		$node_number=$1-1;
		$nodeindex=sprintf("%02d",$node_number);
		$nodename="node"."$nodeindex";
	}
}
system("yum -y install ganglia-gmond");

system("cp /etc/ganglia/gmond.conf /etc/ganglia/gmond.conf.bak");
open ss,"</etc/ganglia/gmond.conf";
@gmond=<ss>;# all available IPs
close ss;
open ss1,">/etc/ganglia/gmond.conf";
foreach(@gmond)
{
	if ($_ =~ /^\s+name \= \"unspecified\"/)
	{
		$_ =~ s/\"unspecified\"/\"$nodename\"/;
	}
	print ss1 "$_";
}
close ss1;
system("systemctl restart gmond");
system("systemctl enable gmond");