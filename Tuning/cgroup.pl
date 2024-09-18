#while true;do echo;done;
#sha1sum /dev/zero
#mount -t cgroup
## systemctl start user-1000.slice
#systemd-cgls
#sha1sum /dev/zero  cpu loading test

#stat -fc %T /sys/fs/cgroup/
#对于 cgroup v2，输出为 cgroup2fs。
#
#对于 cgroup v1，输出为 tmpfs。
=b
group v2 setting
#https://www.jianshu.com/p/89f430efa299
mount|grep cgroup
grubby --update-kernel=ALL --args=systemd.unified_cgroup_hierarchy=1
reboot
mount|grep cgroup

systemd-cgtop
systemd-cgls

display the type of the file system:
stat -fc %T /sys/fs/cgroup/

cat /sys/fs/cgroup/zorro/cpu.max
max 100000
echo 50000 100000 > /sys/fs/cgroup/zorro/cpu.max
=cut

use strict;
use warnings;
#`yum install libcgroup`;
#resource you want to control for UID
my $CPUQuota= '80%';#allowed max cpu usage 
my $MemoryMax= '1024M'; #allowed max ram usage = 20%
my $TasksMax= 50;
my $TasksMaxLimit= 50;# max task number
my $BlockIOMax= "5M";#diso io per second

open my $ss,"< ../username.dat" or die "No username.dat to open.\n $!";#one line for an username
my @temp_array = <$ss>;
close $ss; 
my @user_accounts = grep (($_!~m{^\s*$|^#}),@temp_array); # remove blank lines
map { s/^\s+|\s+$//g; } @user_accounts;
my @UID = map {`id -u $_`;} @user_accounts;
for my $uid (@UID) {
  chomp $uid;
  print "$uid\n";
  my %hash_para = (
      UID => $uid,
      output_file => "user-$uid.slice",
      CPUQuota => "$CPUQuota",
      MemoryMax => "$MemoryMax",
      TasksMax => $TasksMax,
      TasksMaxLimit => $TasksMaxLimit,            
      BlockIOMax => "$BlockIOMax"
      );
  unlink "$hash_para{output_file}";
  `systemctl disable $hash_para{output_file}`;
  `systemctl stop $hash_para{output_file}`;
  `systemctl daemon-reload`;    
  unlink "/usr/lib/systemd/system/$hash_para{output_file}"; 
  `systemctl daemon-reload`;    

  &make_slice_file(\%hash_para);
  `cp $hash_para{output_file} /usr/lib/systemd/system`;
  #`systemctl disable $hash_para{output_file}`;
  #`systemctl stop $hash_para{output_file}`;
  #`systemctl daemon-reload`;

  `systemctl enable $hash_para{output_file}`;
  `systemctl start $hash_para{output_file}`;
#  unlink "$hash_para{output_file}";   
  `systemctl daemon-reload`;

}

sub make_slice_file{

my ($para_hr) = @_;
my $here_doc =<<"END_MESSAGE";
[Unit]
Description= user.slice for $para_hr->{UID}

[Install]
WantedBy=multi-user.target

[Slice]
CPUAccounting=yes
CPUQuota=$para_hr->{CPUQuota}
MemoryAccounting=yes
MemoryMax=$para_hr->{MemoryMax}
TasksAccounting=yes
TasksMax=$para_hr->{TasksMax}
END_MESSAGE
my $temp = $para_hr->{output_file};
chomp $temp;
open(FH, "> $temp") or die $!;
print FH $here_doc;
close(FH);
#`cat << $QEinput > $temp`;
}


# id -u username
#方案二 永久生效
#首先，编写slice文件user-1000.slice
#
#其中1000是orange用户的uid，可用命令查看
#
## id -u username
#
#文件内容如下
#
#[Unit]
#Description=orange user.slice
#
#[Slice]
#User=1001
#CPUQuota=20%
#MemoryMax=100M
#TasksMax=2
#TasksMaxLimit=2
#BlockIOMax=1M
#
## cp user-1000.slice  /usr/lib/systemd/system
## systemctl start user-1000.slice
## systemctl daemon-reload
#
# #systemctl -t slice
# # systemctl status user-1000.slice -l



=b
Based on the code you provided, you should create three systemd slice unit files, one for each UID:

user-1001.slice
user-1002.slice
user-1003.slice
Each file should contain the following content:

[Unit]
Description=My Limited Slice

[Slice]
User=1001
You should replace the 1001 in the User option with the actual UID for each user.

Once you have created the files, you need to save them in the /etc/systemd/system directory.

After that, you need to enable and start the slices. You can do this with the following commands:

for uid in 1001 1002 1003; do
  systemctl enable user-$uid.slice
  systemctl start user-$uid.slice
done

MemoryAccounting=true
MemoryLimit=200M
==cut