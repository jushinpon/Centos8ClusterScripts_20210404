=b
[186_master]
comment = root path
browseable = yes
writable = yes
path = /mnt/
valid users = @samba
create mode = 2775
directory mode = 2775
=cut

#!/usr/bin/perl

use strict;
use warnings;

my $prefix = "186";
my $conf_path = '/etc/samba/smb.conf'; # path of smb.conf
my @extraFolders = `find /mnt/ -maxdepth 2 -mindepth 2 -type d -name "*"`;
my @foldernames;
for (@extraFolders){
chomp;
if (/\/.+\/.+\/(.+)/){push @foldernames, $1;}
}
#print "@extraFolders\n";
#print "@foldernames\n";
`rm -f folders.dat`;
`touch folders.dat`;
`rf -f foldernames.dat`;
`touch foldernames.dat`;
die "folder number is not equal to path number\n" if(@extraFolders != @foldernames);
for (0..$#extraFolders){
    chomp;
    my $temp1 = $extraFolders[$_]; 
    `echo "$temp1" >> folders.dat`;
    my $temp2 = $foldernames[$_]; 
    `echo "$temp2" >> foldername.dat`;

    `echo '[$prefix\_$temp2]
    comment = $prefix\_$temp2
    browseable = yes
    writable = yes
    path = $temp1
    valid users = \@samba
    create mode = 2775
    directory mode = 2775
    ' >> $conf_path
    `;
}