if [ $# -eq 8 ]
then
	benchmarks=$1
	num=$2
	dbnum=$3
	keysize=$4
	valuesize=$5
	cachesize=$6
	threads=$7
	perfflag=$8
	dbdir="/mnt/rocksdb_data/test"
elif [ $# -eq 9 ]
then
	benchmarks=$1
	num=$2
	dbnum=$3
	keysize=$4
	valuesize=$5
	cachesize=$6
	threads=$7
	perfflag=$8
	dbdir=$9
else
	echo para error!
	exit 1
fi

mkdir -p $dbdir

if 	[[ "$benchmarks" == "readrandom" ]] || 
	[[ "$benchmarks" == "readtocache" ]] ||
	[[ "$benchmarks" == "readtorowcache" ]] ||
	[[ "$benchmarks" == "readrandomwriterandom" ]] ||
	[[ "$benchmarks" == "overwrite2" ]] ||
	[[ "$benchmarks" == "multireadrandom" ]]
then
	duration=600
else
	duration=0
fi

if [ "$benchmarks" == "overwrite2" ]
then
	benchmarks="overwrite"
fi

((cache_size=cachesize*1024*1024))
commonpara="--db=${dbdir} --wal_dir=${dbdir} --benchmarks="$benchmarks,stats"
--duration=$duration
--num=$num
--key_size=$keysize
--value_size=$valuesize
--threads=$threads
--cache_size=${cache_size}
"

if [ "$benchmarks" == "readrandomwriterandom" ]
then
	rwpara="--readwritepercent=70"
else
	rwpara=""
fi

cfgfile="../config_file/base_file"
#cfgfile="../config_file/optimize_file"
#cfgfile="../config_file/kvsep_file"
#cfgfile="../config_file/final_file"
cfgfile2="../config_file/file_sys"

cfgpara="
--flagfile=$cfgfile
--flagfile=$cfgfile2
"

perflevel=5
perfpara="--perf_level=$perflevel"

if [ $perfflag -eq 0 ]
then
	perfpara="--perf_level=$perflevel"
else
	perfpara=""
fi

if      [[ "$benchmarks" == "readseq" ]] || 
	[[ "$benchmarks" == "readrandom" ]] ||
       	[[ "$benchmarks" == "readtocache" ]] ||
        [[ "$benchmarks" == "readtorowcache" ]] ||
       	[[ "$benchmarks" == "readrandomwriterandom" ]] ||
        [[ "$benchmarks" == "overwrite" ]] ||
       	[[ "$benchmarks" == "multireadrandom" ]]
then
	ssdcmd="../build/db_bench $commonpara $rwpara -use_existing_db=1 $perfpara $cfgpara"
else
	ssdcmd="../build/db_bench $commonpara $rwpara $perfpara $cfgpara"
fi

if [ $perfflag -eq 0 ]
then
	echo $ssdcmd
fi

sudo sh drop_cache.sh
sleep 1
((cores=32/dbnum))
taskset -c 0-$cores $ssdcmd > perfstatsresult
sh calculate_result.sh $perfflag
