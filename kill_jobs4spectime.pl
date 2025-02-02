#!/usr/bin/perl
use strict;
use warnings;
use POSIX 'strftime';

# Define the keyword to search for
my $keyword = "thermo";

# Define the cutoff date (YYYY-MM-DD)
my $cutoff_date = "2025-01-25";
#my $cutoff_date = "2025-02-02";

# List of computing nodes
my @nodes = ("node01".."node42");

foreach my $node (@nodes) {
    print "Checking node: $node\n";
   # <STDIN>;
    # Check if the node is reachable
    my $ping_result = system("ping -c 1 -W 1 $node > /dev/null 2>&1");
    if ($ping_result != 0) {
        print "Node $node is offline. Skipping...\n";
        next;
    }

    print "Processing node: $node\n";

    # Run the ps command on the remote node
    my @processes = `ssh $node 'ps aux --no-headers | grep $keyword | grep -v grep'`;

    # Debug: Print raw process list
    #print "Raw process list from $node:\n@processes\n";

    foreach my $process (@processes) {
        my @fields = split(/\s+/, $process);

        # Ensure we have enough fields
        next unless scalar @fields >= 10;

        my $pid = $fields[1];  # PID
        my $start_time = $fields[8];  # Start time
        my $command = join(' ', @fields[10..$#fields]);  # Full command

        #print "Found process: PID=$pid, Start Time=$start_time, Command=$command\n";

        # Convert start_time into YYYY-MM-DD format
        my $process_date;
        if ($start_time =~ /^\d{2}:\d{2}$/) {
            # Started today
            $process_date = strftime("%Y-%m-%d", localtime);
        } elsif ($start_time =~ /^([A-Za-z]{3})(\d{1,2})$/) {
            # Convert 'Feb01' to '2025-02-01'
            my ($month, $day) = ($1, $2);
            my %months = (Jan => 1, Feb => 2, Mar => 3, Apr => 4, May => 5, Jun => 6,
                          Jul => 7, Aug => 8, Sep => 9, Oct => 10, Nov => 11, Dec => 12);

            my ($sec, $min, $hour, $mday, $mon, $year) = localtime();
            $year += 1900;  # Convert from Perl's weird year format (year - 1900)

            # Adjust year if the detected month is ahead of the current month (to handle Dec->Jan rollover)
            $year-- if ($months{$month} > $mon + 1);

            $process_date = sprintf("%04d-%02d-%02d", $year, $months{$month}, $day);
        } else {
            print "Skipping process $pid due to unknown time format: $start_time\n";
            next;
        }

        print "Converted Start Date: $process_date\n";

        # Compare dates
        if ($process_date lt $cutoff_date) {
            print "Killing process $pid on $node (Started: $process_date, Command: $command)\n";
            system("ssh $node 'kill -9 $pid'");
        }
    }
}
