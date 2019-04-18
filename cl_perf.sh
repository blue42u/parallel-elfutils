#!/bin/bash
#SBATCH --exclusive
#SBATCH --time=4:00:00
#SBATCH -N 1 -n 1
#SBATCH -o cl_perf.out

TEST=hpc/output.hpcstruct-bin.biginputs_libdyninstAPI.so
if [ -z "$1" ]; then
RUN=latest
else
RUN="$1"
fi

mkdir -p profresults/$RUN

for rep in 1 2 3 4 5; do
rm -rf tests/$TEST.prof.*
for threads in 1 `nproc`; do

make -C tests $TEST.prof.$threads
cd profresults
lua hpcdump.lua ../tests/$TEST.prof.$threads > $RUN/run.$threads.$rep.lua
cd ..

done
done

make -C tests run NONE=1 PROF=1 STABLE=1 BIGGER=1
