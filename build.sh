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
	else
		echo mode only Release or RelWithDebInfo ro Debug !!!!!
		exit 1
	fi
	cmd="cmake $type .."
else
	cmd="cmake $@ .."
fi

rm build -rf
mkdir -p build
cd build
echo $cmd
$cmd
make -j64
cd -
