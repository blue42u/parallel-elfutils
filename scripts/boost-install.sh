mkdir -p tar
pushd tar &> /dev/null
wget --no-check-certificate -N http://downloads.sourceforge.net/project/boost/boost/1.61.0/boost_1_61_0.zip
popd &> /dev/null
unzip tar/boost_1_61_0.zip
cd boost_1_61_0
./bootstrap.sh --with-toolset=intel-linux
./b2 \
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
	--prefix=boost-install -j 16 install
