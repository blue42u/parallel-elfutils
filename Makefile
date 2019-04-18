#----------------------------------------------------------------------------
# get everything downloaded and built for the first time
#----------------------------------------------------------------------------

all: check

dl:
	@if [ ! -e dyninst/CMakeLists.txt ]; then \
		git submodule update --init dyninst; fi
	@if [ ! -e elfutils/configure.ac ]; then \
		git submodule update --init elfutils; fi

#----------------------------------------------------------------------------
# download valgrind, elfutils, boost, and dyninst
#
# warning: 
#   the download step may overwrite any changes you have made
#   understand what you are doing before running this again
#----------------------------------------------------------------------------

INST = $(shell pwd)/install
XFLAGS = -O0 -g
VFLAGS = -I$(INST)/valgrind/include -I$(INST)/.. -include valc++.h

#----------------------------------------------------------------------------
# dyninst test harness for detecting races caused by libdw in elfutils
#----------------------------------------------------------------------------

check: dyninst-build  hpctoolkit-build valgrind
	$(MAKE) -j12 -C tests

prepare: dyninst-build  hpctoolkit-build valgrind
	$(MAKE) -j12 -C tests prep

view:
	$(MAKE) -C tests view

batchdrd: prepare
	sbatch cl_drd.sh

batchval: prepare
	sbatch cl_val.sh

batchperf: prepare
	sbatch cl_perf.sh $(VERSION)

batch: batchdrd batchval batchperf

#----------------------------------------------------------------------------
# dyninst
#----------------------------------------------------------------------------

dyninst-build: dl boost gcc elfutils-build
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
	$(MAKE) -j12 -C build/dyninst install

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
	cd valgrind && $(MAKE) -j 24 install

#----------------------------------------------------------------------------
# GCC (debugging GOMP and libiberty)
#----------------------------------------------------------------------------

gcc:
	@mkdir -p install/gcc download/
	cd download && wget -N ftp://ftp.mirrorservice.org/sites/sourceware.org/pub/gcc/releases/gcc-6.4.0/gcc-6.4.0.tar.xz
	tar xJf download/gcc-6.4.0.tar.xz
	mv gcc-6.4.0 gcc
	cd gcc && ./contrib/download_prerequisites
	cd gcc && CPPFLAGS='-g $(VFLAGS)' ./configure \
		--prefix=$(INST)/gcc --disable-linux-futex --disable-multilib \
		--disable-bootstrap --disable-libquadmath \
		--disable-gcov --disable-libada --disable-libsanitizer \
		--disable-libssp --disable-libquadmath-support \
		--disable-libvtv --enable-install-libiberty
	cd gcc && $(MAKE) -j12
	cd gcc && $(MAKE) -j12 install

#----------------------------------------------------------------------------
# elfutils
#----------------------------------------------------------------------------

elfutils-build: dl
	@mkdir -p build/elfutils install/elfutils
	@cd elfutils && if [ ! -e config/missing ]; then \
		autoreconf -i; fi
	@cd build/elfutils && if [ ! -e Makefile ]; then \
		../../elfutils/configure \
			--enable-maintainer-mode \
			--prefix=$(INST)/elfutils \
			CFLAGS="$(XFLAGS)" \
			INSTALL="$(shell which install) -C"; fi
	$(MAKE) -j12 -C build/elfutils install
	install -C elfutils/libelf/elf.h install/elfutils/include

#----------------------------------------------------------------------------
# hpctookit
#----------------------------------------------------------------------------

hpctoolkit-build: dyninst-build
	@mkdir -p build/hpctoolkit install/hpctoolkit
	@cd build/hpctoolkit && if [ ! -e Makefile ]; then \
		../../hpctoolkit/configure \
			--prefix=$(INST)/hpctoolkit/ \
			--enable-debug \
			--with-binutils=/projects/comp522/jma14/spack/opt/spack/linux-rhel6-x86_64/gcc-6.4.0/binutils-2.31.1-kqv3rcglalogtk6z2goadv7efp3ttxsp \
			--with-boost=$(INST)/boost/ \
			--with-bzip=/projects/comp522/jma14/spack/opt/spack/linux-rhel6-x86_64/gcc-6.4.0/bzip2-1.0.6-4m2m7tcemnvq2sdm6nvodvyvndpj3d44 \
			--with-dyninst=$(INST)/dyninst/ \
			--with-elfutils=$(INST)/elfutils/ \
			--with-tbb=/projects/comp522/jma14/tbb \
			--with-libdwarf=/projects/comp522/jma14/spack/opt/spack/linux-rhel6-x86_64/gcc-6.4.0/libdwarf-20180129-hpfkxw2gbnkbyqz6cwbjecgorb75s6fc \
			--with-libmonitor=/projects/comp522/jma14/spack/opt/spack/linux-rhel6-x86_64/gcc-6.4.0/libmonitor-2018.07.18-ampjrd3icqcmnhrcnitag3cpqjotjtfi \
			--with-libunwind=/projects/comp522/jma14/spack/opt/spack/linux-rhel6-x86_64/gcc-6.4.0/libunwind-2018.10.12-szyxqpyaumq7djnkols36utxgsbc3qf5 \
			--with-xerces=/projects/comp522/jma14/spack/opt/spack/linux-rhel6-x86_64/gcc-6.4.0/xerces-c-3.2.2-jvn3zwe3y226fqxiyzstqahpb57szire \
			--with-lzma=/projects/comp522/jma14/spack/opt/spack/linux-rhel6-x86_64/gcc-6.4.0/xz-5.2.4-42sbhepxxh3yowggil26r476nz7ixcog \
			--with-zlib=/projects/comp522/jma14/spack/opt/spack/linux-rhel6-x86_64/gcc-6.4.0/zlib-1.2.11-l2f3fdpy5urpxsr4prw765g3veaux3og \
			CFLAGS="$(VFLAGS)" \
			LDFLAGS="-L$(INST)/gcc/lib64 -lgomp" \
			--with-xed=/projects/comp522/jma14/spack/opt/spack/linux-rhel6-x86_64/gcc-6.4.0/intel-xed-2018.02.14-hk2unjcjkxmb4ykx7oxb3qnszrb2fxaw \
			--with-perfmon=/projects/comp522/jma14/spack/opt/spack/linux-rhel6-x86_64/gcc-6.4.0/libpfm4-4.10.1-fs4zdgcohg7qovbsbiz22fs22gq5cjdr \
			INSTALL="$(shell which install) -C"; fi
	make -j12 -C build/hpctoolkit install

#----------------------------------------------------------------------------
# maintenance
#----------------------------------------------------------------------------

distclean:
	rm -rf boost
	rm -rf valgrind
