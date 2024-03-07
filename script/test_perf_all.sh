num1=1342177280 #总IO数
basedir="/mnt/rocksdb_data/test"
prefix="../test_data/test_perf_cache10%_final"
mkdir -p $basedir

keyarr=(64 64 128)
valuearr=(128 512 1024)
for kv in 0 1 2
do
	key=${keyarr[$kv]}
	value=${valuearr[$kv]}
	echo $key $value
	for dbnum in 32 16 8
	do
		((cores=32/dbnum))
		((threads=cores*4))
		((num=num1/dbnum))
		((cs=128*1024/dbnum))
		outdir="${prefix}_singledb${dbnum}_k${key}_v${value}_threads${threads}"
		mkdir -p $outdir
		curdir="singledb${dbnum}_cores${cores}_threadN_cs${cs}"
		dbdir=$basedir/$curdir
		sh test_perf_single.sh fillseq $num $dbnum $key $value $cs 1 1 $dbdir > ${outdir}/fillseq_oplog
		mv perfstatsresult ${outdir}/fillseq_perfstats
		cp $dbdir/LOG ${outdir}/fillseq_LOG
		sh test_perf_single.sh overwrite $num $dbnum $key $value $cs 1 1 $dbdir > ${outdir}/overwrite_oplog
                mv perfstatsresult ${outdir}/overwrite_perfstats
                cp $dbdir/LOG ${outdir}/overwrite_LOG

		for mod in "randwrite" "readrandom" "r7w3"
		do
			if [ "$mod" == "randwrite" ]
			then
				mode1="overwrite2"
			elif [ "$mod" == "r7w3" ]
			then
				mode1="readrandomwriterandom"
			else
				mode1="readrandom"
			fi

			sh test_perf_single.sh ${mode1} $num $dbnum $key $value $cs $threads 1 $dbdir
			sh test_perf_single.sh ${mode1} $num $dbnum $key $value $cs $threads 1 $dbdir
			sh test_perf_single.sh ${mode1} $num $dbnum $key $value $cs $threads 1 $dbdir > ${outdir}/${mod}_oplog
			mv perfstatsresult ${outdir}/${mod}_perfstats
	                cp $dbdir/LOG ${outdir}/${mod}_LOG
		done

		echo ---------------------------------------------------------
		echo perfresult:
		for mod in "fillseq" "overwrite" "randwrite" "readrandom" "r7w3"
		do
			cat ${outdir}/${mod}_oplog
		done
	done
done
