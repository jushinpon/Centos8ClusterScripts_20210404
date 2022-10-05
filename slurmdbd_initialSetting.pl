=b
systemctl status maridb
cp my.cnf to /etc/my.cnf.d/
systemctl restart maridb
systemctl enable maridb
=cut

use strict;
use warnings;
`cp my.conf /etc/my.cnf.d/`; # for slurm reconfig