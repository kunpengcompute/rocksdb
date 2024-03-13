perfflag=$1

arr1=(
block_cache_hit_count
)

arr2=(
bytes_written
)

#cat perfstatsresult
ssd1=`cat perfstatsresult|grep operation |tail -1`
ssd2=`cat perfstatsresult|grep user_key_comparsion_count |tail -1`
ssd3=`cat perfstatsresult|grep thread_pool_id |tail -1`

if [ $perfflag -eq 0 ]
then
	echo SSD:$ssd1
fi

lat1=`echo $ssd1 |awk '{print $3}'`
iops1=`echo $ssd1 |awk '{print $5}'`
time1=`echo $ssd1 |awk '{print $7}'`
ionum1=`echo $ssd1 |awk '{print $9}'`
bandwith1=`echo $ssd1 |awk '{print $11}'`

if [ $perfflag -ne 0 ]
then
	if [ "$benchmarks" == "readrandomwriterandom" ]
	then
		benchmarks="randr7w3"
		bandwith1=""
	fi
	echo ""
	echo $benchmarks $'\t' $lat1 $'\t' $'\t' $iops1 $'\t' $time1 $'\t' $'\t' $ionum1 $'\t' $bandwith1
	exit
fi
