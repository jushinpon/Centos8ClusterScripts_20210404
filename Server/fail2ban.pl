#https://rdfarm.net/fail2ban-firewalld-centos-7-cc-attacks/
#https://snippetinfo.net/mobile/media/2570
system ("dnf install fail2ban");
system ("rm /etc/fail2ban/jail.local");
#system ("mkdir -p /etc/fail2ban");
system ("touch /etc/fail2ban/jail.local");
$jaillocal = '/etc/fail2ban/jail.local';
$ignoreIP = '140.117.0.0/16';
$bantime = '86400';
`echo "[DEFAULT]\n" >> $jaillocal`;
`echo "ignoreip = $ignoreIP" >>$jaillocal`;
`echo "bantime = $bantime"   >> $jaillocal`;
`echo "findtime = 600"   >> $jaillocal`;
`echo "maxretry = 10"   >> $jaillocal`;
`echo "banaction = firewallcmd-ipset"   >> $jaillocal`;
`echo "backend = systemd" >>  $jaillocal`;
`echo "[sshd]">>  $jaillocal`;
`echo "enabled = true">>  $jaillocal`;
system ("systemctl start fail2ban");
system ("systemctl enable fail2ban");
system ("systemctl status fail2ban");
#fail2ban-client status    <<<<  Use this Command to Check inmates 
#fail2ban-client status sshd   <<<<  Use this Command to Check Who is that inmates


