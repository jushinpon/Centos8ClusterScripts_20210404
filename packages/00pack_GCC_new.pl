#Perl script to install GCC of different version, because the Centos has a very old GCC version in default.
#Developed by Prof. Shin-Pon Ju
#1. You may refer to this web: https://www.softwarecollections.org/en/scls/rhscl/devtoolset-7/
#2. need to install Env::Modify for Perl system call 
#3. need to install cpan and then do "cpan -i -f CPAN::Meta::Feature" first. Otherwise the installation of Env::Modify could be failed. 

=b (not make it for perl currently)
yum install glibc-devel.i686 libgcc.i686 libstdc++-devel.i686 ncurses-devel.i686
#Making sure we are not missing any 32bit libraries since we are on a 64bit machine
yum install glibc.i686 ncurses-libs.i686;
#Download the source code
wget http://ftp.gnu.org/gnu/gcc/gcc-4.8.2/gcc-4.8.2.tar.gz;
#Extract the files
tar -xvf gcc-4.8.2.tar.gz;
#Navigate to the folder
cd gcc-4.8.2/;
#Make sure we have all dependencies met
./contrib/download_prerequisites;
#Configure the installation and assign the installation folder to be /usr/local/gcc/4.8.2. Finally make all necessary checks before compilation.
./configure --prefix=/usr/local/gcc/4.8.2;
#Build
make;
#Install
sudo make install;
=cut

use warnings;
use strict;
use Env::Modify qw(:sh source);
use Cwd; #Find Current Path
use File::Copy; # Copy File
system("yum install -y centos-release-scl");
my @GCC_Version = (7,8,9); # Please use the lastest three versions for test.
for my $GV (@GCC_Version){
    print "\n\n**** gcc version before upgraded\n\n";
    system ("gcc -v");
    chomp $GV;
    `yum install devtoolset-$GV -y`;
    source("/opt/rh/devtoolset-$GV/enable"); # enable GCC of this version for current shell and all subshell
    #system("scl enable devtoolset-9 bash"); # enable GCC of this version for system
    print "\n\n---> gcc version AFTER upgraded\n\n";
    system ("gcc -v");
}
print "\n\n**** GCC has been upgraded\n\n";
