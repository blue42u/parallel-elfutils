mkdir -p tar
pushd tar &> /dev/null
wget -N http://www.valgrind.org/downloads/valgrind-3.14.0.tar.bz2
popd &> /dev/null
mkdir -p pkgs
pushd pkgs &> /dev/null
tar xvjf ../tar/valgrind-3.14.0.tar.bz2
ln -s valgrind-3.14.0 valgrind
pushd valgrind &> /dev/null
mkdir -p valgrind-build valgrind-install
pushd valgrind-build &> /dev/null
BOOST=`pwd`/../../../boost_1_61_0/boost-install
export CPPFLAGS="-I$BOOST/include -L$BOOST/lib"
../configure --prefix=`pwd`/../valgrind-install
make -j install
popd &> /dev/null
popd &> /dev/null
