#!/bin/sh

#SBATCH --job-name=5nmPtPd
##SBATCH --output=mpi405_100stepsmpirun_%j.log
#SBATCH --output=5nmPtPd_%j.log
#SBATCH --nodes=1
##SBATCH --hint=nomultithread
##SBATCH --ntasks-per-node=12
#SBATCH --partition=debug
##SBATCH --threads-per-core=1
##SBATCH --nodelist=node[02-03] #,node01
##SBATCH --exclusive
#/root/mpich_download/mpich-3.3.1/mpich_install/bin/mpiexec -np 8 /root/qe_download/q-e-qe-6.4.1/bin/pw.x -in scf_1.in 

#export LD_LIBRARY_PATH=/opt/mvapich2-2.3.5-4slurm/lib:/opt/intel/mkl/lib/intel64:$LD_LIBRARY_PATH
#export PATH=/opt/mvapich2-2.3.5-4slurm/bin:$PATH
#export LD_LIBRARY_PATH=/opt/mvapich2-2.3.5-srunMrail/lib:/opt/intel/mkl/lib/intel64:$LD_LIBRARY_PATH
#export PATH=/opt/mvapich2-2.3.5-srunMrail/bin:$PATH
export LD_LIBRARY_PATH=/opt/mpich-3.4.1/lib:$LD_LIBRARY_PATH
export PATH=/opt/mpich-3.4.1/bin:$PATH
#export LD_LIBRARY_PATH=/opt/mpich-3.3.2/lib:/opt/intel/mkl/lib/intel64:$LD_LIBRARY_PATH
#export PATH=/opt/mpich-3.3.2/bin:$PATH

#export LD_LIBRARY_PATH=/opt/openmpi-4.1.0/lib:/opt/UCX-1.9/lib:$LD_LIBRARY_PATH
#export PATH=/opt/openmpi-4.1.0/bin:/opt/UCX-1.9/bin:$PATH
#export OMPI_MCA_btl_openib_allow_ib=1
#export OMPI_MCA_btl_openib_if_include="rxe0:1 MV2 USE RDMA CM=1"
#--mpi=openmpi -env UCX_NET_DEVICES=rxe0:1
#mpiexec MV2_DEFAULT_PORT=1 MV2_IBA_HCA=rxe0:1 /opt/lammps-mpich-3.4_UCX/lmp_20210109 -in Tension.in 
#export MV2_HOMOGENEOUS_CLUSTER=1
#export MV2_IBA_EAGER_THRESHOLD=32K
#srun --mpi=pmi2 /opt/lammps-mvapich-2.3.5_srunMrail/lmp_20210223 -in Tension.in 
#UCX_LOG_LEVEL=info mpirun --mca pml ucx -x UCX_NET_DEVICES=rxe0:1 -x UCX_IB_GID_INDEX=1 /opt/lammps-openmpi-4.1.0/lmp_20210119 -in Tension.in
#mpirun -mca pml ucx -mca btl ^uct -x UCX_NET_DEVICES=rxe0:1 /opt/lammps-openmpi-4.1.0/lmp_20210119 -in Tension.in
#mpirun --mca btl_openib_receive_queues P,65536,120,64,32 --mca btl_openib_cpc_include rdmacm 
#mpirun --mca orte_base_help_aggregate 10 --mca pml ucx -mca btl ^uct 
#mpirun --mca btl ^vader,tcp,openib,uct
#--mca btl_openib_cpc_base_exclude rdmacm 
#mpirun --mca pml ucx --mca btl tcp,self --mca btl_base_verbose 100 --mca btl_openib_cpc_exclude rdmacm /opt/lammps-openmpi-4.1.0/lmp_20210119 -in Tension.in
#mpiexec  -env UCX_NET_DEVICES=mlx5_0:1 /opt/lammps-mpich-3.3.2/lmp_20201223 -in Tension.in
mpiexec /opt/lammps-mpich-3.4.1/lmp_20210223 -in tension_5nmPtPd.in
#export UCX_IB_GID_INDEX=3
#UCX_IB_SL=<sl-num>
#export OMP_NUM_THREADS=2 
#mpiexec  -env UCX_NET_DEVICES=mlx5_0:1 -env UCX_IB_GID_INDEX=3 -env UCX_IB_SL=2 /opt/lammps-mpich-3.4.1/lmp_20210223 -in Tension.in
#mpiexec  -iface enp1s0 /opt/lammps-mpich-3.3.2/lmp_20201223 -in Tension.in
#mpirun --mca pml ob1 --mca bt openib,self,vader --mca btl_openib_cpc_include rdmacm --mca btl_openib_rroce_enable 1 \
#/opt/lammps-openmpi-4.1.0/lmp_20210119 -in Tension.in
#mpiexec /opt/lammps-openmpi-4.1.0/lmp_20210119 -in Tension.in 
#mpiexec --bind-to core --mca btl tcp,self,vader  --mca btl_tcp_if_include p3p2 /opt/lammps-mpich-3.4_UCX/lmp_20210109 -in Tension.in 
#mpirun /opt/lammps-openmpi-4.0.5/lmp_mpi -in Tension.in 
# /opt/mpich_install/bin/mpiexec -np 8 /opt/qe_install/bin/pw.x -in scf_1.in
