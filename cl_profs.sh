#!/bin/bash
#SBATCH --exclusive
#SBATCH --time=2:00:00
#SBATCH -N 1 -n 1
#SBATCH -o cl_profs.out

TEST=hpc/output.hpcstruct-bin.biginputs_libdyninstAPI.so
if [ -z "$1" ]; then
RUN=latest
else
RUN="$1"
fi

mkdir -p profresults/$RUN

for rep in 1 2 3 4 5; do
rm -rf tests/$TEST.prof.*
for threads in 1 12; do

make -C tests $TEST.prof.$threads
cd profresults
lua hpcdump.lua ../tests/$TEST.prof.$threads > $RUN/run.$threads.$rep.lua
cd ..

done
done
