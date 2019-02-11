WORK=`pwd`/..
BOOST_ROOT=${WORK}/boost_1_61_0/boost-install

DYNINST_ROOT=${WORK}/dyninst/dyninst-install

TARGET=cilk-parse

PMODEL_OPT="-g "


build: stefan.o $(TARGET) 

$(TARGET): ../elfutils/elfutils-install/lib/libdw.so ../dyninst/dyninst-install/lib/libsymtabAPI.so
	make -f Makefile.dyninst BOOST_ROOT=$(BOOST_ROOT) DYNINST_ROOT=$(DYNINST_ROOT) TARGET=$(TARGET) PMODEL_OPT=$(PMODEL_OPT)

stefan.o: stefan.c

check:
	./check

clean:
	/bin/rm -rf stefan.o cilk-parse cilk-parse.o

.PHONY: check
