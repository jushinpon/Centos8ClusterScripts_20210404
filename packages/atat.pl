=b
The script helps you install ATAT.
You need to install lapack, blacs, and scalapack in advance.

Official website:
http://brown.edu/Departments/Engineering/Labs/avdw//atat/

=cut

use warnings;
use strict;
use Cwd; # Find Current Path

`yum install tcsh -y`;
# 設定下載與安裝的目錄
my $packageDir = "/home/packages";
if (!-e $packageDir) { # 如果 /home/packages 不存在，則建立資料夾
    system("mkdir -p $packageDir");
}

# 設定變數
my $URL = "http://alum.mit.edu/www/avdw/atat/atat3_36.tar.gz";
my $Dir4download = "$packageDir/atat_download"; # ATAT 的下載目錄
my $installDir = "/opt/atat/bin/"; # 安裝 ATAT 的目錄
`rm -rf /opt/atat`;
# 下載 ATAT
print "Downloading ATAT...\n";
system("rm -rf $Dir4download");
system("mkdir $Dir4download");
chdir("$Dir4download");
system("wget $URL -O atat.tar.gz") == 0 or die "Failed to download ATAT!\n";

# 解壓縮
print "Extracting ATAT...\n";
system("tar -xvf atat.tar.gz") == 0 or die "Failed to extract ATAT!\n";
#system("mv atat $installDir");
chdir("$Dir4download/atat")|| die "NO $Dir4download/atat\n";
# Use Perl's system call to run sed
my $sed_command = "sed -i 's|^BINDIR=\\\$(HOME)/bin/|BINDIR=/opt/atat/|' ./makefile";
`rm -rf /opt/atat/bin/`;
`mkdir -p /opt/atat/bin/`;
system($sed_command) == 0 or die "Failed to execute sed command: $!";

# 切換到 ATAT 目錄並編譯
#chdir("$installDir");

# 獲取 CPU 執行緒數量
my $thread4make = `lscpu | grep "^CPU(s):" | awk '{print \$2}'`;
chomp $thread4make;
print "Total threads available for make: $thread4make\n";

# 編譯 ATAT
print "Compiling ATAT...\n";
system("make -j $thread4make") == 0 or die "Failed to compile ATAT!\n";

# 安裝 ATAT
print "Installing ATAT...\n";
system("make install") == 0 or die "Failed to install ATAT!\n";

## 設定環境變數
#print "Setting up environment variables...\n";
#my $bashrc = "$ENV{HOME}/.bashrc";
#my $exportPath = "export PATH=\$PATH:$installDir/bin";
#system("echo '$exportPath' >> $bashrc");

print "Installation completed! You may need to restart the shell.\n";
