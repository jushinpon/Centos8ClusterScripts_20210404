system ("dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm");
system ("dnf install fail2ban");
system ("rm /etc/fail2ban/jail.local");
system ("touch jail.local");
$jaillocal = '/etc/fail2ban/jail.local';
$ignoreIP = '140.117.0.0/24';
$bantime = '999999';
`echo "[DEFAULT]\n" >> $jaillocal`;
`echo "ignoreip = $ignoreIP" >>$jaillocal`;
`echo "bantime = $bantime"   >> $jaillocal`;
`echo "findtime = 100"   >> $jaillocal`;
`echo "maxretry = 3"   >> $jaillocal`;
`echo "banaction = iptables-multiport"   >> $jaillocal`;
`echo "backend = systemd" >>  $jaillocal`;
`echo "[sshd]">>  $jaillocal`;
`echo "enabled = true">>  $jaillocal`;
system ("systemctl start fail2ban");
system ("systemctl enable fail2ban");
system ("systemctl status fail2ban");
#fail2ban-client status    <<<<  Use this Command to Check inmates 
#fail2ban-client status sshd   <<<<  Use this Command to Check Who is that inmates


