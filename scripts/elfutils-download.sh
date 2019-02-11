git clone https://github.com/jmellorcrummey/elfutils
cd elfutils
git checkout parallel
autoreconf -i -f 

mkdir elfutils-build elfutils-install
cd elfutils-build
../configure --enable-maintainer-mode --prefix=`pwd`/../elfutils-install
