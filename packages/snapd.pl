#Perl script to Downlaod and install snapd developed by Prof. Shin-Pon Ju (2023/an/28)
# You need to be root to use this script

system ("dnf install epel-release -y");
system ("dnf install snapd -y");
system ("systemctl enable snapd.socket --now");
`rm -f /var/lib/snapd/snap`;
system ("ln -s /var/lib/snapd/snap /snap");
print "*******snapd installation DONE!\n";
#snap install supercell
