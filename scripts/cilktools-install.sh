mkdir tar > /dev/null 2>&1 
pushd tar  > /dev/null 2>&1 
wget --no-check-certificate http://cilkplus.org/sites/default/files/cilk_tools/cilktools-linux-004501.tgz
popd > /dev/null 2>&1 
mkdir pkgs > /dev/null 2>&1 
pushd pkgs > /dev/null 2>&1 
tar xzf ../tar/cilktools-linux-004501.tgz
ln -s cilktools-linux-004501 cilktools
