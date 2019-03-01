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

download: gcc boost valgrind elfutils-dl dyninst-dl

#----------------------------------------------------------------------------
# dyninst test harness for detecting races caused by libdw in elfutils
#----------------------------------------------------------------------------

check: dyninst-build valgrind
	$(MAKE) -C tests

last:
	$(MAKE) -C tests last

#----------------------------------------------------------------------------
# dyninst
#----------------------------------------------------------------------------

dyninst-dl:
	@if [ ! -e dyninst/CMakeLists.txt ]; then \
		git submodule update --init dyninst; fi

dyninst-build: boost gcc elfutils-build dyninst-dl
	@mkdir -p build/dyninst install/dyninst
	@cd build/dyninst && if [ ! -e Makefile ]; then cmake \
		-DCMAKE_CXX_FLAGS="$(XFLAGS)" -DCMAKE_C_FLAGS="$(XFLAGS)" \
		-DBoost_NO_BOOST_CMAKE=ON -DBOOST_ROOT=$(INST)/boost -DBoost_NO_SYSTEM_PATHS=ON \
		-DBoost_INCLUDE_DIR=$(INST)/boost/include -DBoost_LIBRARY_DIR=$(INST)/boost/lib \
		-DCMAKE_INSTALL_PREFIX=$(INST)/dyninst \
		-DCMAKE_CXX_FLAGS="-DENABLE_VG_ANNOTATIONS" \
		-DLIBELF_INCLUDE_DIR=$(INST)/elfutils/include \
		-DLIBELF_LIBRARIES=$(INST)/elfutils/lib/libelf.so \
		-DLIBDWARF_INCLUDE_DIR=$(INST)/elfutils/include \
		-DLIBDWARF_LIBRARIES=$(INST)/elfutils/lib/libdw.so \
		-DIBERTY_LIBRARIES=$(INST)/gcc/lib64/libiberty.a \
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
	cd boost && ./bootstrap.sh
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
		--disable-libssp --disable-libquadmath-support \
		--disable-libvtv --enable-install-libiberty
	cd gcc && $(MAKE) -j
	cd gcc && $(MAKE) -j install

#----------------------------------------------------------------------------
# elfutils
#----------------------------------------------------------------------------

elfutils-dl:
	@if [ ! -e elfutils/configure.ac ]; then \
		git submodule update --init elfutils; fi

elfutils-build: elfutils-dl
	@mkdir -p build/elfutils install/elfutils
	@cd elfutils && if [ ! -e config/missing ]; then \
		autoreconf -i; fi
	@cd build/elfutils && if [ ! -e Makefile ]; then \
		../../elfutils/configure \
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
