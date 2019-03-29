#!/bin/bash
#SBATCH --time=5:00:00
#SBATCH -N 1 -n 1 -c 1
#SBATCH -o cl_val.out

make -C tests run DRD=1 BIG=1
make -C tests run BIGGER=1
