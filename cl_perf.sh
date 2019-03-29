#!/bin/bash
#SBATCH --exclusive
#SBATCH --time=2:00:00
#SBATCH -N 1 -n 1
#SBATCH -o cl_perf.out

make -C tests run PROF=1 STABLE=1
