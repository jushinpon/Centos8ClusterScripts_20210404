use warnings;
use strict;

my @cmd = ("ssh", "top", "htop", "ps");

foreach my $command (@cmd) {
    my $path = "/usr/bin/$command";

    if (-e $path) {  # Check if the file exists
        chmod 0750, $path or warn "Failed to set 750 permissions on $path: $!";
    } else {
        warn "$path does not exist.";
    }
}