module load GCCcore/6.4.0
module load GCC/6.4.0
module load icc/2018.2.199-GCC-6.4.0
module load CMake/3.10.3
export LD_LIBRARY_PATH="`pwd`/install/gcc/lib:`pwd`/install/gcc/lib64:${LD_LIBRARY_PATH}"
