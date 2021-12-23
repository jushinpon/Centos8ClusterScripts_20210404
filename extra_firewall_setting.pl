system ("firewall\-cmd \-\-zone\=external \\
  \-\-add\-rich\-rule\=\'rule family\=\"ipv4\" source address\=\"140\.117\.0\.0\/16\" accept\' \\
  \-\-permanent");
  
  system ("$cmd --reload");