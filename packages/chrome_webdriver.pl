#!/usr/bin/perl
=b
pip install selenium (don't use conda to install selenium)
make a txt file, chrome.txt:
chrome_url=https://storage.googleapis.com/chrome-for-testing-public/132.0.6834.83/linux64/chrome-linux64.zip
chromedriver_url=https://storage.googleapis.com/chrome-for-testing-public/132.0.6834.83/linux64/chromedriver-linux64.zip

https://googlechromelabs.github.io/chrome-for-testing/#stable


/opt/webdriver/chromedriver --version

rm -rf *chrome*
wget https://storage.googleapis.com/chrome-for-testing-public/132.0.6834.83/linux64/chrome-linux64.zip
unzip chrome-linux64.zip

rm -rf /opt/google
mkdir -p /opt/google/chrome
cp -R * /opt/google/chrome/
chmod -R 755 /opt/google

wget https://storage.googleapis.com/chrome-for-testing-public/132.0.6834.83/linux64/chromedriver-linux64.zip
unzip chromedriver-linux64.zip 
rm -rf /opt/webdriver
mkdir -p  /opt/webdriver
cd chromedriver-linux64/
cp -R * /opt/webdriver/
chmod -R 755 /opt/webdriver

mkdir -p /tmp/Crashpad
chmod -R 777 /tmp/Crashpad/
=cut


use strict;
use warnings;
use File::Path qw(make_path remove_tree);
use File::Copy;

# Variables
my $config_file = "chrome.txt";
my $download_dir = "/home/packages/chrome_related";
my $chrome_url;
my $chromedriver_url;
my $chrome_install_dir = "/opt/google/chrome";
my $chromedriver_install_dir = "/opt/webdriver";
my $crashpad_dir = "/tmp/Crashpad";

# Read URLs from chrome.txt
sub read_config {
    open my $fh, '<', $config_file or die "Cannot open $config_file: $!";
    while (my $line = <$fh>) {
        chomp($line);
        if ($line =~ /^chrome_url=(.+)$/) {
            $chrome_url = $1;
        } elsif ($line =~ /^chromedriver_url=(.+)$/) {
            $chromedriver_url = $1;
        }
    }
    close $fh;

    die "chrome_url not found in $config_file" unless $chrome_url;
    die "chromedriver_url not found in $config_file" unless $chromedriver_url;
}

# Helper subroutine to run shell commands
sub run_command {
    my $cmd = shift;
    print "Running: $cmd\n";
    my $output = `$cmd 2>&1`;
    die "Error: $output" if $? != 0;
    print "$output\n";
}

# Step 1: Prepare download directory
sub prepare_download_dir {
    print "Preparing download directory at $download_dir...\n";
    remove_tree($download_dir) if -d $download_dir;
    make_path($download_dir);
}

# Step 2: Download and extract Chrome
sub install_chrome {
    print "Downloading Google Chrome from $chrome_url...\n";
    chdir($download_dir) or die "Cannot change to directory: $download_dir";
    run_command("wget -q $chrome_url -O chrome-linux64.zip");
    run_command("unzip -q chrome-linux64.zip");

    print "Installing Chrome to $chrome_install_dir...\n";
    remove_tree($chrome_install_dir) if -d $chrome_install_dir;
    make_path($chrome_install_dir);
    run_command("cp -R $download_dir/chrome-linux64/* $chrome_install_dir");
    run_command("chmod -R 755 /opt/google");
}

# Step 3: Download and extract ChromeDriver
sub install_chromedriver {
    print "Downloading ChromeDriver from $chromedriver_url...\n";
    chdir($download_dir) or die "Cannot change to directory: $download_dir";
    run_command("wget -q $chromedriver_url -O chromedriver-linux64.zip");
    run_command("unzip -q chromedriver-linux64.zip");

    print "Installing ChromeDriver to $chromedriver_install_dir...\n";
    remove_tree($chromedriver_install_dir) if -d $chromedriver_install_dir;
    make_path($chromedriver_install_dir);
    chdir("chromedriver-linux64/") or die "Cannot change directory: chromedriver-linux64/";
    run_command("cp -R $download_dir/chromedriver-linux64/* $chromedriver_install_dir/");
    run_command("chmod -R 755 $chromedriver_install_dir");
}

# Step 4: Setup Crashpad directory
sub setup_crashpad {
    print "Setting up Crashpad directory at $crashpad_dir...\n";
    make_path($crashpad_dir);
    run_command("chmod -R 777 $crashpad_dir");
}

# Main Script Execution
read_config();
prepare_download_dir();
install_chrome();
install_chromedriver();
setup_crashpad();

print "Installation complete!\n";
