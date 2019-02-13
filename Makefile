#----------------------------------------------------------------------------
# get everything downloaded and built for the first time
#----------------------------------------------------------------------------

all: download build test1-build

build: elfutils-build dyninst-config dyninst-build test1-build

#----------------------------------------------------------------------------
# download cilktools, elfutils, boost, and dyninst
#
# warning: 
#   the download step may overwrite any changes you have made
#   understand what you are doing before running this again
#----------------------------------------------------------------------------

download: cilktools-download elfutils-download boost-install dyninst-download 
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
	scripts/dyninst-download.sh

dyninst-config:
	scripts/dyninst-config.sh

dyninst-build:
	make -C dyninst/dyninst-build install

#----------------------------------------------------------------------------
# boost
#----------------------------------------------------------------------------

boost-install:
	scripts/boost-install.sh

#----------------------------------------------------------------------------
# cilktools
#----------------------------------------------------------------------------

cilktools-download:
	scripts/cilktools-install.sh 

#----------------------------------------------------------------------------
# elfutils
#----------------------------------------------------------------------------

elfutils-download:
	scripts/elfutils-download.sh

elfutils-build:
	make -j -C elfutils/elfutils-build install

elfutils-remove:
	/bin/rm -rf elfutils

#----------------------------------------------------------------------------
# maintenance
#----------------------------------------------------------------------------

distclean:
	scripts/cilktools-uninstall.sh 
