cd dyninst
mkdir dyninst-build dyninst-install
cd dyninst-build
PWD=`pwd`
ROOT=$PWD/../..
cmake \
        -DPATH_BOOST=$ROOT/boost_1_61_0/boost-install \
	-DCMAKE_INSTALL_PREFIX=$PWD/../dyninst-install \
	-DCMAKE_CXX_FLAGS="-DENABLE_VG_ANNOTATIONS -I$PWD/../../pkgs/valgrind/valgrind-install/include" \
	-DLIBELF_INCLUDE_DIR=$ROOT/elfutils/elfutils-install/include \
	-DLIBELF_LIBRARIES=$ROOT/elfutils/elfutils-install/lib/libelf.so \
	-DLIBDWARF_INCLUDE_DIR=$ROOT/elfutils/elfutils-install/include \
	-DLIBDWARF_LIBRARIES=$ROOT/elfutils/elfutils-install/lib/libdw.so \
	-DCMAKE_C_COMPILER=`which icc` \
	-DCMAKE_BUILD_TYPE=Debug \
	-DCMAKE_CXX_COMPILER=`which icpc` \
	..
