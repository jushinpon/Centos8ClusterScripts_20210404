#Perl script to install GCC of different version, because the Centos has a very old GCC version in default.
#Developed by Prof. Shin-Pon Ju
#1. You may refer to this web: https://www.softwarecollections.org/en/scls/rhscl/devtoolset-7/
#2. need to install Env::Modify for Perl system call 
#3. need to install cpan and then do "cpan -i -f CPAN::Meta::Feature" first. Otherwise the installation of Env::Modify could be failed. 
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
