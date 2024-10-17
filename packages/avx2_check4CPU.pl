grep -m1 'flags' /proc/cpuinfo | grep -o 'avx[^ ]*'
lscpu | grep 'Flags'
When Compiling Software Like Quantum ESPRESSO:
Check Your CPU's Capabilities:

Verify whether your specific Intel Core i7 CPU model supports AVX, AVX2, or AVX-512 before choosing compiler flags.
Use Appropriate Compiler Flags:

For AVX:

bash
Copy code
-xAVX
For AVX2:

bash
Copy code
-xCORE-AVX2
For AVX-512 (if supported):

bash
Copy code
-xCORE-AVX512
Avoid Using -xHost in Heterogeneous Environments:

If compiling on a different machine than the target, -xHost may produce binaries incompatible with the target CPU.
Ensure Compatibility in Cluster Environments:

Compile for the Lowest Common Denominator:
If using a cluster with mixed CPU capabilities, target the instruction set supported by all nodes.