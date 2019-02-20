#----------------------------------------------------------------------------
# get everything downloaded and built for the first time
#----------------------------------------------------------------------------

all: download build test1-build

build: elfutils-build dyninst-config dyninst-build test1-build

#----------------------------------------------------------------------------
# download valgrind, elfutils, boost, and dyninst
#
# warning: 
#   the download step may overwrite any changes you have made
#   understand what you are doing before running this again
#----------------------------------------------------------------------------

download: boost-install valgrind-install elfutils-download dyninst-download
	echo > download

#----------------------------------------------------------------------------
# dyninst test harness for detecting races caused by libdw in elfutils
#----------------------------------------------------------------------------

test1-build: 
	make -C test1

#----------------------------------------------------------------------------
# dyninst
#----------------------------------------------------------------------------

dyninst-download:
	git submodule update --init dyninst

dyninst-config:
	scripts/dyninst-config.sh
	touch dyninst-config

dyninst-build:
	make -j -C dyninst/dyninst-build install

#----------------------------------------------------------------------------
# boost
#----------------------------------------------------------------------------

boost-install:
	scripts/boost-install.sh

#----------------------------------------------------------------------------
# valgrind
#----------------------------------------------------------------------------

valgrind-download:
	scripts/valgrind-install.sh 

#----------------------------------------------------------------------------
# elfutils
#----------------------------------------------------------------------------

elfutils-download:
	git submodule update --init dyninst

elfutils-build:
	make -j -C elfutils/elfutils-build install

#----------------------------------------------------------------------------
# maintenance
#----------------------------------------------------------------------------

distclean:
	/bin/rm -rf boost_1_61_0
	/bin/rm -rf pkgs
