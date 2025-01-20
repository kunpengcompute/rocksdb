if [ $# -eq 0 ]
then
	cmd="cmake -DCMAKE_BUILD_TYPE=Release .."
else
	mode=$1
	pos=2
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
		type="-DCMAKE_BUILD_TYPE=Release"
		pos=1
	fi
	for((i=$pos;i<=$#;i++));
	do
		if [ ${!i} == "DISABLE_KSAL" ]
		then
			type="$type -DWITH_KSAL=OFF"
		elif [ ${!i} == "DISABLE_KP_OPT" ]
		then
			type="$type -DWITH_KP_OPT=OFF"
		elif [ ${!i} == "DISABLE_KAEZSTD" ]
		then
			type="$type -DENABLE_KAEZSTD=OFF"
		else
			echo Usage:
			echo sh build.sh [mode] [options]
			echo mode: Release, RelWithDebInfo, Debug or UTONLY
			echo options: DISABLE_KSAL, DISABLE_KP_OPT, DISABLE_KAEZSTD
			exit 1
		fi
	done
	cmd="cmake $type .."
fi
#cmd=$cmd" -DWITH_KSAL=OFF -DWITH_KP_OPT=ON"
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
