#----------------------------------------------------------------------------
# get everything downloaded and built for the first time
#----------------------------------------------------------------------------

all: download build check

build: elfutils-build dyninst-build test1-build

#----------------------------------------------------------------------------
# download valgrind, elfutils, boost, and dyninst
#
# warning: 
#   the download step may overwrite any changes you have made
#   understand what you are doing before running this again
#----------------------------------------------------------------------------

INST = $(shell pwd)/install

download: boost valgrind elfutils dyninst

#----------------------------------------------------------------------------
# dyninst test harness for detecting races caused by libdw in elfutils
#----------------------------------------------------------------------------

test1-build: dyninst-build
	$(MAKE) -j -C test1

check:
	$(MAKE) -j -C test1 check

#----------------------------------------------------------------------------
# dyninst
#----------------------------------------------------------------------------

dyninst:
	git submodule update --init dyninst

dyninst-build: boost dyninst
	@mkdir -p build/dyninst install/
	@cd build/dyninst && if [ ! -e Makefile ]; then cmake \
		-DCMAKE_CXX_FLAGS="-O3" -DCMAKE_C_FLAGS="-O3" \
	        -DPATH_BOOST=$(INST) \
		-DCMAKE_INSTALL_PREFIX=$(INST) \
		-DCMAKE_CXX_FLAGS="-DENABLE_VG_ANNOTATIONS -I$(INST)" \
		-DLIBELF_INCLUDE_DIR=$(INST)/include \
		-DLIBELF_LIBRARIES=$(INST)/lib/libelf.so \
		-DLIBDWARF_INCLUDE_DIR=$(INST)/include \
		-DLIBDWARF_LIBRARIES=$(INST)/lib/libdw.so \
		-DCMAKE_BUILD_TYPE=Debug \
		../../dyninst; fi
	$(MAKE) -j -C build/dyninst install

#----------------------------------------------------------------------------
# boost
#----------------------------------------------------------------------------

boost:
	@mkdir -p install/ download/
	cd download && wget --no-check-certificate -N http://downloads.sourceforge.net/project/boost/boost/1.61.0/boost_1_61_0.zip
	unzip -qo download/boost_1_61_0.zip
	mv boost_1_61_0 boost
	cd boost && ./bootstrap.sh --with-toolset=intel-linux
	cd boost && ./b2 \
		--with-system \
		--with-thread \
		--with-date_time \
		--with-filesystem \
		--with-timer \
		--with-atomic \
		--ignore-site-config \
		--link=static \
		--runtime-link=shared \
		--layout=tagged \
		--threading=multi \
		--prefix=../install -j 16 install

#----------------------------------------------------------------------------
# valgrind
#----------------------------------------------------------------------------

valgrind: boost
	@mkdir -p install/ download/
	cd download && wget -N http://www.valgrind.org/downloads/valgrind-3.14.0.tar.bz2
	tar xjf download/valgrind-3.14.0.tar.bz2
	mv valgrind-3.14.0 valgrind
	cd valgrind && CPPFLAGS="-I$(INST)/include -L$(INST)/lib" \
		./configure --prefix=$(INST)
	cd valgrind && $(MAKE) -j install

#----------------------------------------------------------------------------
# elfutils
#----------------------------------------------------------------------------

elfutils:
	git submodule update --init elfutils

elfutils-build: elfutils
	@mkdir -p build/elfutils
	@cd elfutils && if [ ! -e config/missing ]; then \
		autoreconf -i; fi
	@cd build/elfutils && if [ ! -e Makefile ]; then \
		../../elfutils/configure \
			--enable-maintainer-mode \
			--prefix=$(INST) \
			CFLAGS="-g -O3"; fi
	$(MAKE) -j -C build/elfutils install

#----------------------------------------------------------------------------
# maintenance
#----------------------------------------------------------------------------

distclean:
	rm -rf boost
	rm -rf valgrind
