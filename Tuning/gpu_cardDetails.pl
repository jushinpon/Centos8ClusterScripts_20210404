=b
  You need to conduct gpu_driver_install.pl (for nvidia-smi) 
  and gpu_cuda_pgi.pl (for /opt/nvidia/hpc_sdk/Linux_x86_64/21.9/compilers/bin/pgaccelinfo) first. 
=cut
use Parallel::ForkManager;
use Cwd;
#my $currentPath = getcwd();

$forkNo = 1;
my $pm = Parallel::ForkManager->new("$forkNo");
my @nodes = (8..18,20..22);

#+++++++++++ parameters you need to assign correctly!!!!!
my $gpu_info = "yes";#check and output gpu card information for all nodes
#!!! if yes for $blacklist4nouveau, you need to set @nodes for gpu nodes only
my $blacklist4nouveau = "no";#make /etc/modprobe.d/blacklist-nouveau.conf or not
#after rebooting, use the following to install gpu card driver
#use a larger value for $forkNo 
my $install_driver = "no";#instll nvidai driver(not work currently),you need to install one by one
my $driver = "/home/rtx2060/NVIDIA-Linux-x86_64-470.74.run";

#my $setgresconf = "yes";#set gres.conf
#my $gresconf_dir = "/usr/local/etc/";#for replacing gres.conf, the same dir as slurm.conf
#`rm -f gres.conf`;
#`touch gres.conf`;
#for (@nodes){
#    $nodeindex=sprintf("%02d",$_);
#    $nodename= "node"."$nodeindex";
#    $cmd = "ssh $nodename ";
#    print "****Check $nodename status\n ";
#    system("$cmd 'ls /dev/nvidia0'");
#    print "?no gpu device at $nodename\n" if($?); 
#    `echo "NodeName=$nodename Name=gpu File=/dev/nvidia0" >> gres.conf`;
#}

#++++++++++++++++++++++

$output;#gpu_info output file
if($gpu_info eq "yes"){
    $output = "./gpu_cardInfo.dat";
    `rm -f $output`;
    `touch $output`;
}
 
for (@nodes){

$pm->start and next;
    $nodeindex=sprintf("%02d",$_);
    $nodename= "node"."$nodeindex";
    $cmd = "ssh $nodename ";
    print "****Check $nodename status\n ";
    #`echo "***$nodename" >> $output`;

#get Nvidia GPU card information for finding the proper driver
    if($gpu_info eq "yes"){
        my @gpucard = `$cmd 'lspci|grep NVIDIA|grep VGA'`;
        chomp @gpucard;
        my $allGPU = join(" ",@gpucard);
        if(@gpucard){
            `echo "" >> $output`;
            `echo "$nodename GPU card info: $allGPU" >> $output`;
            my @lsmod = `$cmd "lsmod | grep nouveau"`;
            chomp @lsmod;
            my $lsmod = join(" ",@lsmod);
            `echo "lsmod output $lsmod" >> $output`;            
        }
        else{#no GPU card
            `echo '' >> $output`;        
            `echo "No GPU card in $nodename" >> $output`;  
        }# 
    }#gpu_card information

#set blacklist for nouveau 
    if($blacklist4nouveau eq "yes"){
        my $file = `$cmd "ls /etc/modprobe.d/blacklist-nouveau.conf"`;
        chomp $file;
        if($?){#no blacklist-nouveau.conf
            `$cmd 'touch /etc/modprobe.d/blacklist-nouveau.conf'`;
            `$cmd 'echo "blacklist nouveau" >> /etc/modprobe.d/blacklist-nouveau.conf'`;
            `$cmd 'echo "options nouveau modeset=0" >> /etc/modprobe.d/blacklist-nouveau.conf'`;
            `$cmd 'dracut --force'`;
            `$cmd 'reboot'`;
        }
        else{#blacklist-nouveau.conf exists!!
            my $grepKeyW = `$cmd "grep 'blacklist' /etc/modprobe.d/blacklist-nouveau.conf"`;
            unless($grepKeyW){
                `$cmd 'echo "blacklist nouveau" >> /etc/modprobe.d/blacklist-nouveau.conf'`;
            }
            $grepKeyW = `$cmd "grep 'options nouveau' /etc/modprobe.d/blacklist-nouveau.conf"`;
            unless($grepKeyW){
                `$cmd 'echo "options nouveau modeset=0" >> /etc/modprobe.d/blacklist-nouveau.conf'`;
            }
        }
        
    }#blacklist4nouveau

    if($install_driver eq "yes"){
       system("$cmd \"echo -e 'Accept'|$driver\"");
       print "test nvidia-smi for $nodename\n";
       `$cmd "nvidia-smi"`;

    }


   $pm->finish;

}
$pm->wait_all_children;


