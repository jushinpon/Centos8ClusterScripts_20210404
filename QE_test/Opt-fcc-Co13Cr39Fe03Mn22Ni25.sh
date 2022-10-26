#!/bin/sh
#sed_anchor01
#SBATCH --output=Opt-fcc-Co13Cr39Fe03Mn22Ni25.sout
#SBATCH --job-name=Opt-fcc-Co13Cr39Fe03Mn22Ni25
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=12

##SBATCH --nodes=12
#SBATCH --partition=debug

threads=`lscpu|grep "^CPU(s):" | sed 's/^CPU(s): *//g'`
SLURM_NTASKS=$threads #--ntasks-per-node=8
export SLURM_NTASKS
SLURM_JOB_CPUS_PER_NODE=$threads
export SLURM_JOB_CPUS_PER_NODE

echo "threads: $threads"
echo "SLURM_MEM_PER_CPU: $SLURM_MEM_PER_CPU"
echo "SLURM_MEM_PER_NODE: $SLURM_MEM_PER_NODE"
echo "SLURM_JOB_NUM_NODES: $SLURM_JOB_NUM_NODES"
echo "SLURM_NNODES: $SLURM_NNODES"
echo "SLURM_NTASKS: $SLURM_NTASKS"
echo "SLURM_CPUS_PER_TASK: $SLURM_CPUS_PER_TASK"
echo "SLURM_JOB_CPUS_PER_NODE: $SLURM_JOB_CPUS_PER_NODE"

export LD_LIBRARY_PATH=/opt/mpich-3.4.2/lib:/opt/intel/mkl/lib/intel64:$LD_LIBRARY_PATH
export PATH=/opt/mpich-3.4.2/bin:$PATH
#sed_anchor02
mpiexec /opt/QEGCC_MPICH3.4.2/bin/pw.x -in Opt-fcc-Co13Cr39Fe03Mn22Ni25.in




