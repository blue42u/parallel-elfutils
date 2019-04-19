#!/bin/bash
#SBATCH --time=7:00:00
#SBATCH -N 1 -n 1 -c 12
#SBATCH -o cl_drd.out

make -j 12 -C tests run NONE=1 DRD=1 BIG=1
