#!/bin/bash
#SBATCH --time=12:00:00
#SBATCH -N 1 -n 1 -c 12
#SBATCH -o cl_val.out

make -j 12 -C tests run DRD=1 BIG=1
make -j 12 -C tests run BIGGER=1
