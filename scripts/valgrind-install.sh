mkdir -p tar
pushd tar &> /dev/null
wget -N http://www.valgrind.org/downloads/valgrind-3.14.0.tar.bz2
popd &> /dev/null
mkdir -p pkgs
pushd pkgs &> /dev/null
tar xvjf ../tar/valgrind-3.14.0.tar.bz2
ln -s valgrind-3.14.0 valgrind
pushd valgrind
./configure
make -j
popd &> /dev/null
