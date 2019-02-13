set up your environment
	source scripts/environment.sh

download and build everything, including a test harness for detecting
races caused by elfutils

	make 

run the test harness to detect races caused by elfutils

	cd test1
	make check

output of the race detector will be placed in a timestamped typescript file 

after you have built dyninst for the first time, you can add the -j16 flag 
to the dyninst-build target. I had some problems adding parallelism for the first build as dyninst built some dependences, but it works fine (and faster) with a -j16 parallel build to build changes.

note: the makefile in the test1 directory is crude. it will not rebuild 
the binary for cilk-parse if one of the libraries (e.g., dyninst symtabAPI or
libdw) has changed. you can rebuild cilk-parse easily with
	make clean
	make

and then retest with
	make check 
	 
for historical reasons, the test1 directory has three interacting
makefiles.  makefile is the top-level one used when make is run. makefile
employs Makefile, which employs Makefile.dyninst to get everything
built. feel free to rewrite it if you want. it works, so I can live
with it.
