mkdir -p tar
pushd tar &> /dev/null
/bin/rm -rf valgrind-3.14.0.tar.bz2
popd &> /dev/null
mkdir -p pkgs
pushd pkgs &> /dev/null
/bin/rm -rf valgrind-3.14.0
/bin/rm -f valgrind
popd &> /dev/null
