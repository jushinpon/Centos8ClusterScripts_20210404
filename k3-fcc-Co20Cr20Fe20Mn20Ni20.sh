#!/bin/sh
#sed_anchor01
#SBATCH --output=k3-fcc-Co20Cr20Fe20Mn20Ni202.sout
#SBATCH --job-name=k3-fcc-Co20Cr20Fe20Mn20Ni20
#SBATCH --nodes=1
#SBATCH --partition=16Cores


export LD_LIBRARY_PATH=/opt/mpich-3.4.2/lib:/opt/intel/mkl/lib/intel64:$LD_LIBRARY_PATH
export PATH=/opt/mpich-3.4.2/bin:$PATH
#sed_anchor02
mpiexec /opt/QEGCC_MPICH3.4.2/bin/pw.x -in k3-fcc-Co20Cr20Fe20Mn20Ni20.in




