my @packages = (
    #"mpich4GCC_devices",
    "lammps",
    "QE_thermoPW",
    "cmake",
    "lapack",
    "atomsk",
    "gromacs"
);
system("dnf install -y numactl-devel");#for mpich config
for (@packages){
    chomp;
    system("perl $_.pl");
}