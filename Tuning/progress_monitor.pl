use warnings;
use strict;
use Cwd; #Find Current Path
my $currentPath = getcwd();
system("dnf install -y ncurses-devel");
system("git clone https://github.com/Xfennec/progress.git");
system("git clone https://github.com/Xfennec/progress.git");
chdir("$currentPath/progress");
system("make");
system("make install");
system("install progress done!!\n");
