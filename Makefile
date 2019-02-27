#----------------------------------------------------------------------------
# get everything downloaded and built for the first time
#----------------------------------------------------------------------------

all: download build check

build: elfutils-build dyninst-build

#----------------------------------------------------------------------------
# download valgrind, elfutils, boost, and dyninst
#
# warning: 
#   the download step may overwrite any changes you have made
#   understand what you are doing before running this again
#----------------------------------------------------------------------------

INST = $(shell pwd)/install
XFLAGS = -O0 -g

download: gcc boost valgrind elfutils dyninst

#----------------------------------------------------------------------------
# dyninst test harness for detecting races caused by libdw in elfutils
#----------------------------------------------------------------------------

check: dyninst-build
	$(MAKE) -C test1

last:
	$(MAKE) -C test1 last

#----------------------------------------------------------------------------
# dyninst
#----------------------------------------------------------------------------

dyninst:
	git submodule update --init dyninst

dyninst-build: boost dyninst
	@mkdir -p build/dyninst install/dyninst
	@cd build/dyninst && if [ ! -e Makefile ]; then cmake \
		-DCMAKE_CXX_FLAGS="$(XFLAGS)" -DCMAKE_C_FLAGS="$(XFLAGS)" \
	        -DBOOST_ROOT=$(INST)/boost -DPATH_BOOST=$(INST)/boost \
		-DCMAKE_INSTALL_PREFIX=$(INST)/dyninst \
		-DCMAKE_CXX_FLAGS="-DENABLE_VG_ANNOTATIONS" \
		-DLIBELF_INCLUDE_DIR=$(INST)/elfutils/include \
		-DLIBELF_LIBRARIES=$(INST)/elfutils/lib/libelf.so \
		-DLIBDWARF_INCLUDE_DIR=$(INST)/elfutils/include \
		-DLIBDWARF_LIBRARIES=$(INST)/elfutils/lib/libdw.so \
		-DCMAKE_BUILD_TYPE=Debug \
		../../dyninst; fi
	$(MAKE) -j -C build/dyninst install

#----------------------------------------------------------------------------
# boost
#----------------------------------------------------------------------------

boost:
	@mkdir -p install/boost download/
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
		--prefix=../install/boost -j 16 install

#----------------------------------------------------------------------------
# valgrind
#----------------------------------------------------------------------------

valgrind: boost
	@mkdir -p install/valgrind download/
	cd download && wget -N http://www.valgrind.org/downloads/valgrind-3.14.0.tar.bz2
	tar xjf download/valgrind-3.14.0.tar.bz2
	mv valgrind-3.14.0 valgrind
	cd valgrind && CPPFLAGS="-I$(INST)/boost/include -L$(INST)/boost/lib" \
		./configure --prefix=$(INST)/valgrind
	cd valgrind && $(MAKE) -j install

#----------------------------------------------------------------------------
# GCC (really just libgomp)
#----------------------------------------------------------------------------

gcc:
	@mkdir -p install/gcc download/
	cd download && wget -N ftp://ftp.mirrorservice.org/sites/sourceware.org/pub/gcc/releases/gcc-6.4.0/gcc-6.4.0.tar.xz
	tar xJf download/gcc-6.4.0.tar.xz
	mv gcc-6.4.0 gcc
	cd gcc && ./contrib/download_prerequisites
	cd gcc && CPPFLAGS='-g' ./configure \
		--prefix=$(INST)/gcc --disable-linux-futex --disable-multilib \
		--disable-bootstrap --disable-libquadmath \
		--disable-gcov --disable-libada --disable-libsanitizer \
		--disable-libssp --disable-libquadmath-support --disable-libvtv
	cd gcc && $(MAKE) -j
	cd gcc && $(MAKE) -j install

#----------------------------------------------------------------------------
# elfutils
#----------------------------------------------------------------------------

elfutils:
	git submodule update --init elfutils

elfutils-build: elfutils
	@mkdir -p build/elfutils install/elfutils
	@cd elfutils && if [ ! -e config/missing ]; then \
		autoreconf -i; fi
	@cd build/elfutils && if [ ! -e Makefile ]; then \
		../../elfutils/configure \
			--enable-maintainer-mode \
			--prefix=$(INST)/elfutils \
			CFLAGS="$(XFLAGS)" \
			INSTALL="$(shell which install) -C"; fi
	$(MAKE) -j -C build/elfutils install

#----------------------------------------------------------------------------
# maintenance
#----------------------------------------------------------------------------

distclean:
	rm -rf boost
	rm -rf valgrind
