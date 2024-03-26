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

num_warmup=0
if [ "$benchmarks" == "overwrite2" ]
then
	benchmarks="overwrite"
	num_warmup=2
fi

if [ "$benchmarks" == "readrandom" ]
then
	num_warmup=2
fi

if [ "$benchmarks" == "readrandomwriterandom" ]
then
	num_warmup=2
fi

cachetype=0 # 0:blockcache, 1:kvcache
((cache_size=cachesize*1024*1024))
((cores=32/dbnum))
if [ $cachetype -eq 0 ]
then
	cachepara="--cache_size=${cache_size}"
else
	cachepara="--cache_size=8338608 --row_cache_size=${cache_size} --row_cache_type=compact_cache"
fi

commonpara="--db=${dbdir} --wal_dir=${dbdir} --benchmarks="$benchmarks[-W${num_warmup}],stats"
--duration=$duration
--num=$num
--key_size=$keysize
--value_size=$valuesize
--threads=$threads
 $cachepara
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

cfgfilebak="../config_file/tmp"

cp $cfgfile $cfgfilebak

cfgpara="
--flagfile=$cfgfilebak
--flagfile=$cfgfile2
"

#-------------------------根据核数设置参数-----------------------------------#
oldjobs=`sed -n 's/^--max_background_jobs=\(.*\)$/\1/p' $cfgfilebak`
oldflushes=`sed -n 's/^--max_background_flushes=\(.*\)$/\1/p' $cfgfilebak`
oldcomp=`sed -n 's/^--max_background_compactions=\(.*\)$/\1/p' $cfgfilebak`
oldnum=`sed -n 's/^--max_write_buffer_number=\(.*\)$/\1/p' $cfgfilebak`

((newjobs=cores*4))
((newflushes=cores*2))
((newcomp=cores*1))
((newnum=cores*2))

sed -i 's/\(max_background_jobs=\).*/\1'${newjobs}'/g' $cfgfilebak
sed -i 's/\(max_background_flushes=\).*/\1'${newflushes}'/g' $cfgfilebak
sed -i 's/\(max_background_compactions=\).*/\1'${newcomp}'/g' $cfgfilebak
sed -i 's/\(max_write_buffer_number=\).*/\1'${newnum}'/g' $cfgfilebak

perflevel=5
perfpara="--perf_level=$perflevel"

if [ $perfflag -eq 1 ]
then
	perfpara=""
fi

if	[[ "$benchmarks" == "readseq" ]] ||
	[[ "$benchmarks" == "readrandom" ]] ||
	[[ "$benchmarks" == "readtocache" ]] ||
	[[ "$benchmarks" == "readtorowcache" ]] ||
	[[ "$benchmarks" == "readrandomwriterandom" ]] ||
	[[ "$benchmarks" == "overwrite" ]] ||
	[[ "$benchmarks" == "multireadrandom" ]]
then
	ssdcmd="../build/db_bench $commonpara $rwpara --use_existing_db=1 $perfpara $cfgpara"
else
	ssdcmd="../build/db_bench $commonpara $rwpara $perfpara $cfgpara"
fi

if [ $perfflag -eq 0 ]
then
	echo $ssdcmd
fi

sudo sh drop_cache.sh
sleep 1
((coreidx=cores-1))
echo taskset -c 0-$coreidx $ssdcmd
taskset -c 0-$coreidx $ssdcmd > perfstatsresult
sh calculate_result.sh $perfflag

rm -f $cfgfilebak
