target="shared_lib static_lib tools db_bench"
if [ $# -eq 0 ]
then
	cmd="DEBUG_LEVEL=0 PORTABLE=1 make $target -j32"
else
	mode=$1
	if [ "$mode" == "Release" ]
	then
		type="DEBUG_LEVEL=0"
	elif [ "$mode" == "RelWithDebInfo" ]
	then
		type="DEBUG_LEVEL=1"
	elif [ "$mode" == "Debug" ]
	then
		type="DEBUG_LEVEL=2"
	else
		echo Usage options: Release, RelWithDebInfo, Debug
		exit 1
	fi
	cmd="$type PORTABLE=1 make $target -j32"
fi

make clean

echo $cmd
eval $cmd