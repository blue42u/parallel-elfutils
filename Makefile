all: download build test1-build

download: cilktools-download elfutils-download boost-install dyninst-download 
	echo > download

build: elfutils-build dyninst-config dyninst-build test1-build

test1-build: 
	make -C test1


elfutils-build:
	make -j -C elfutils/elfutils-build install

dyninst-download:
	scripts/dyninst-download.sh

dyninst-config:
	scripts/dyninst-config.sh

dyninst-build:
	make -C dyninst/dyninst-build -j16 install

boost-install:
	scripts/boost-install.sh

cilktools-download:
	scripts/cilktools-install.sh 

elfutils-download:
	scripts/elfutils-download.sh

distclean:
	scripts/cilktools-uninstall.sh 

elfutils-remove:
	/bin/rm -rf elfutils
