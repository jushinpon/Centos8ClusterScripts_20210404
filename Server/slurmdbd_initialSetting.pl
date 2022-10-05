=b
systemctl status maridb
cp my.cnf to /etc/my.cnf.d/
systemctl restart maridb
systemctl enable maridb
=cut

use strict;
use warnings;
`cp my.cnf /etc/my.cnf.d/`; # for mariadb
system("./mariadb_setup.sh");
system("systemctl restart mariadb");