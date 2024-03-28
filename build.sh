if [ $# -eq 0 ]
then
	cmd="cmake -DCMAKE_BUILD_TYPE=Release .."
elif [ $# -eq 1 ]
then
	mode=$1
	if [ "$mode" == "Release" ]
	then
		type="-DCMAKE_BUILD_TYPE=Release"
	elif [ "$mode" == "RelWithDebInfo" ]
	then
		type="-DCMAKE_BUILD_TYPE=RelWithDebInfo"
	elif [ "$mode" == "Debug" ]
	then
		type=""
	elif [ "$mode" == "UTONLY" ]
	then
                type="-DWITH_ALL_TESTS=OFF"
	else
		echo mode only Release or RelWithDebInfo ro Debug !!!!!
		exit 1
	fi
	cmd="cmake $type .."
else
	cmd="cmake $@ .."
fi
cmd=$cmd" -DDISABLE_KSAL=ON"
rm build -rf
mkdir -p build
cd build
echo $cmd
$cmd
if [ "$mode" == "UTONLY" ]
then
	make check -j32	
	ret=$?
	cd -
	exit $ret
fi
make -j32
cd -
