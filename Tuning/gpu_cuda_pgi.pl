=b
You need to use nvidia-smi to check the higest version of cuda your gpu card support  

CUDA Toolkit: 
https://developer.nvidia.com/cuda-downloads
or
https://developer.nvidia.com/cuda-toolkit-archive

NVIDIA HPC SDK:
https://developer.nvidia.com/nvidia-hpc-sdk-downloads

After pgi installation, you may check the details of your gpu card by the folllowing command (path could be different):
 /opt/nvidia/hpc_sdk/Linux_x86_64/21.9/compilers/bin/pgaccelinfo

=cut
use Parallel::ForkManager;
use Cwd;
#my $currentPath = getcwd();
#Cuda Toolkit setting for nvcc cuda compiler (nvcc --version)
#export CUDA_HOME=/usr/local/cuda-11.4
#export PATH=$PATH:$CUDA_HOME/bin
#export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CUDA_HOME/lib64


