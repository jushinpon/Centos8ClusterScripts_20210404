#Perl script to Downlaod and install supercell developed by Prof. Shin-Pon Ju (2023/an/28)
# You need to be root to use this script
system("dnf install -y libarchive-dev libboost-program-options-dev libboost-filesystem-dev \\
libboost-random-dev libboost-system-dev libtbb-dev libeigen3-dev");
#`rm -rf supercell`;
#system("git clone --recursive https://github.com/orex/supercell.git && cd supercell && \\
system("cd supercell && \\
  mkdir build && cd build && cmake ../ && make && sudo make install");

print "*******supercell installation DONE!\n";
