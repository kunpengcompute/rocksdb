#!/usr/bin/python

# usage: python ./run_all_test.py [config.cvs] <enable_perf> <perf_level>


import csv
import re
import sys
import os
import time
import subprocess
import logging

class Log:
    def __init__(self, filename):
        self.logger = logging.getLogger(filename)
        self.logger.setLevel(logging.DEBUG)
        tmode = 'a' if self.logger.handlers else 'w'
        
        fmt = "[%(asctime)s][%(filename)s][%(lineno)d][%(levelname)s][%(message)s]"
        formatter = logging.Formatter(fmt)
        
        fh = logging.FileHandler(filename, mode=tmode)
        fh.setLevel(logging.DEBUG)
        fh.setFormatter(formatter)

        sh = logging.StreamHandler()
        sh.setLevel(logging.DEBUG)
        sh.setFormatter(formatter)
        self.logger.handlers = []
        self.logger.addHandler(fh)
        self.logger.addHandler(sh)
    def info(self, message):
        self.logger.info(message)
    def debug(self, message):
        self.logger.debug(message)
    def warm(self, message):
        self.logger.warm(message)
    def error(self, message):
        self.logger.error(message)


ENABLE_PERF = 0
PERF_LEVEL = 0

#LD_PRELOAD='LD_RELOAD=/home/zjy/final/libmemcpy_noprefetch_nov8_1k.so'
LD_PRELOAD=""
ENVS=['LD_LIBRARY_PATH','/home/zjy/base/build']

def exec_command(command, logger=None):
    if (logger):
        logger.info(command)
    r = os.popen(command)
    text = r.read()
    r.close()
    return text


keys = ['casename', 'cpu_mask', 'iops',
'lat(us)', 'rlat(us)', 'P50_rlat', 'P99_rlat',  
'wlat(us)', 'P50_wlat', 'P99_wlat']

default_db_params = [
"--disable_seek_compaction=1",
"--mmap_read=0",
"--statistics=1",
"--histogram=1",
"--bloom_bits=10",
"--cache_numshardbits=4",
"--open_files=500000",
"--verify_checksum=1",
"--stats_interval=1000000",
"--compression_ratio=1",
"--disable_data_sync=0",
"--target_file_size_base=134217728",
"--max_write_buffer_number=3",
"--max_bytes_for_level_multiplier=10",
"--max_background_compactions=10",
"--num_levels=10",
"--delete_obsolete_files_period_micros=3000000",
"--max_grandparent_overlap_factor=10",
"--stats_per_interval=1",
"--max_bytes_for_level_base=537395200",
]



def mkdir(dir_path, logger=None):
    dir_path = dir_path.strip()
    dir_path = dir_path.rstrip("\\")
    is_exists = os.path.exists(dir_path)
    if not is_exists:
        os.makedirs(dir_path.encode('utf-8'))
    if logger:
        logger.info("create path:" + dir_path)


def get_file_name(filename):
    file_base_name = os.path.basename(filename)
    lists = os.path.splitext(file_base_name)
    return lists[-2]

class DBBenchRunner():
    def __init__(self, casenum, dicts, output_dir, logger):
        self.logger = logger
        self.dicts = dicts
        self.casename = str(casenum) + "_" + dicts['casename']
        self.cpu_mask = dicts['cpu_mask']

        self.db_params = []
        self.OUTPUT_DIR = output_dir
        self.OUTPUT_CASE_DIR = self.OUTPUT_DIR + "/testcases"
        self.RUN_LOG = self.OUTPUT_DIR + "/run.log"

        self.ROOT_DIR = os.path.dirname(os.path.dirname(self.OUTPUT_DIR))
        self.CONFIG_FILE = self.OUTPUT_CASE_DIR + "/" + self.casename
        self.OUTPUT_FILE = self.CONFIG_FILE + "_db_bench.txt"
        self.DB_BENCH = self.ROOT_DIR + "/build/db_bench"
        self._gen_config()
        self.drop_cache()

    def drop_cache(self):
        cmd = "echo 3 > /proc/sys/vm/drop_caches"
        self.run_command(cmd, self.RUN_LOG, self.RUN_LOG)
      
    
    def _gen_config(self):
        warmup_num = ""
        bencher=""
        for key in self.dicts.keys():
            if key in keys:
                continue
            if key == 'readwritepercent':
                if self.dicts['readwritepercent'] != '0':
                    self.db_params.append(("--" + key + "=" + self.dicts[key]))
            elif key == 'flags1' or key == 'flags2':
                flags_dir = os.path.abspath(self.ROOT_DIR + "/" + self.dicts[key])
                self.db_params.append(("--flagfile=" + flags_dir ))
            elif key == 'warmup':
                warmup_num = (self.dicts[key])
            elif key == 'benchmarks':
                bencher = self.dicts[key]
            else:
                self.db_params.append(("--" + key + "=" + self.dicts[key]))
                if key == 'report_interval_seconds' and self.dicts[key] != '0':
                    self.db_params.append(("--report_file=" + self.CONFIG_FILE + "_report.csv"))
        if warmup_num != '0':
            self.db_params.append("--benchmarks=" + bencher + "[-W" + warmup_num +"],stats")
        else:
            self.db_params.append("--benchmarks=" + bencher + ",stats")
        if PERF_LEVEL > 0:
            self.db_params.append("--perf_level=" + str(PERF_LEVEL))
            

        fo = open(self.CONFIG_FILE, "w")
        fo.write("\n".join(self.db_params))
        fo.flush()
        fo.close()

    def trace_perf(self, case_file, loopnum):
        perffile = case_file + loopnum + ".perf"
        memperffile = case_file + "_mem" + loopnum +  ".perf"
        perf_result_file = case_file + "_perf" + loopnum + ".txt"
        memperf_result_file = case_file + "_memperf" + loopnum +  ".txt"
        cmd = "/usr/bin/perf record -g -C " + self.cpu_mask + " -o " + perffile + " sleep 5"
        exec_command(cmd, self.logger)

        cmd = "perf record -a -e arm_spe_0/ts_enable=1,load_filter=1,store_filter=1,min_latency=0/ -C " + self.cpu_mask + " -o " + memperffile + " sleep 5"
        exec_command(cmd, self.logger)

        cmd = "top -i -1 -n 10 -b &> " + case_file + "_top" + loopnum + ".txt"
        exec_command(cmd, self.logger)

        cmd = "iostat -x -k 1 10 &> " + case_file + "_iostat" + loopnum + ".txt"
        exec_command(cmd, self.logger)

        cmd = "/usr/bin/perf report -i " + perffile + " > " + perf_result_file
        exec_command(cmd, self.logger)
        cmd = "/usr/bin/perf report -i " + memperffile + " > " + memperf_result_file
        exec_command(cmd, self.logger)
        cmd = "rm -rf " + perffile + " " + memperffile
        exec_command(cmd, self.logger)

        

    def run_command(self, command, output_file, error_file, case_file = None):
        out_file = open(output_file, "w+")
        err_file = open(error_file, "w+")
        self.logger.info("executing... - " + command)
        p = subprocess.Popen(command, shell=True, stdout=out_file, stderr=err_file)
        if case_file:
            time.sleep(10)
            self.trace_perf(case_file, "1");
            if (self.dicts['benchmarks'] == 'overwrite'):
                time.sleep(200)
                self.trace_perf(case_file, "2");
        p.wait()
        out_file.flush()
        out_file.close()
        err_file.flush()
        err_file.close()



    def run_benchmark(self):
        # Your benchmarking code goes here
        cmd = LD_PRELOAD + " time taskset -c " + self.cpu_mask + " " + self.DB_BENCH + " --flagfile=" + self.CONFIG_FILE + " | tee " + self.OUTPUT_FILE 
        if ENABLE_PERF == 1:
            self.run_command(cmd, self.RUN_LOG, self.RUN_LOG, self.CONFIG_FILE)
        else:
            self.run_command(cmd, self.RUN_LOG, self.RUN_LOG)

        cmd = "cp " + self.dicts['db'] + "/LOG " + self.CONFIG_FILE + "_log.txt"
        self.run_command(cmd, self.RUN_LOG, self.RUN_LOG)
        self._parser_iops_lat(self.OUTPUT_FILE)
    
    def _parser_iops_lat(self, output_file):
        write_batch = 32
        #if self.dicts['batch_size']:
            #write_batch = int(self.dicts['batch_size'])
        cmd = "cat " + output_file + " | grep " + self.dicts['benchmarks'] + " | tail -1"
        bench_out_text = exec_command(cmd, self.logger)

        cmd = "cat " + output_file + " | grep \"Microseconds per read\" -A 3"
        read_out_text = exec_command(cmd, self.logger)

        cmd = "cat " + output_file + " | grep \"Microseconds per write\" -A 3"
        write_out_text = exec_command(cmd, self.logger)


        iops_lat_partten = re.compile('.* ([0-9\.]+) micros/op ([0-9]+) ops/sec .*')
        match = iops_lat_partten.match(bench_out_text)
        if match:
            self.dicts['iops'] = match.group(2)
            self.dicts['lat(us)'] = match.group(1)

        lat_partten = re.compile('.* Average: ([0-9\.]+).*')
        match = lat_partten.search(read_out_text, re.MULTILINE)
        if match:
            self.dicts['rlat(us)'] = match.group(1)
        
        match = lat_partten.search(write_out_text, re.MULTILINE)
        if match:
            self.dicts['wlat(us)'] = str(float(match.group(1))/write_batch)
        
        lat_dist_partten = re.compile('.* P50: ([0-9\.]+) .* P99: ([0-9\.]+) .*')
        match = lat_dist_partten.search(read_out_text, re.MULTILINE)
        if match:
            self.dicts['P50_rlat'] = match.group(1)
            self.dicts['P99_rlat'] = match.group(2)
        
        match = lat_dist_partten.search(write_out_text, re.MULTILINE)
        if match:
            self.dicts['P50_wlat'] = str(float(match.group(1))/write_batch)
            self.dicts['P99_wlat'] = str(float(match.group(2))/write_batch)


    def export_results(self):
        # Your exporting code goes here
        return self.dicts

class AllCaseRunner:
    def __init__(self, cur_dir, test_case_file):
        self.CUR_DIR = cur_dir
        self.TEST_CASE_FILE = test_case_file
        self.RESULT_DIR = self.CUR_DIR + "/result/"
        self.DB_BENCH = self.CUR_DIR + "/build/db_bench"
        
        self._create_and_get_dirs()
        self._set_up()

    def _create_and_get_dirs(self):
        self.OUTPUT_DIR = self.RESULT_DIR + get_file_name(self.TEST_CASE_FILE) + "_" + time.strftime("%Y%m%d%H%M%S", time.localtime())
        self.OUTPUT_CASE_DIR = self.OUTPUT_DIR + "/testcases"
        self.RESULT_FILE = self.OUTPUT_DIR + "/" + os.path.basename(test_case_file)
        self.RUN_LOG = self.OUTPUT_DIR + "/run.log"
        mkdir(self.OUTPUT_DIR)
        mkdir(self.OUTPUT_CASE_DIR)
        self.logger = Log(self.OUTPUT_DIR + "/logging.log")
        self.logger.info(self.RESULT_FILE)

    def _set_up(self):
        self.f = open(self.TEST_CASE_FILE, encoding="utf-8-sig", mode="r")
        self.reader = csv.DictReader(self.f)
        self.wf = open(self.RESULT_FILE, encoding="utf-8-sig", mode="w", newline='')
        self.writer = csv.DictWriter(self.wf, fieldnames=self.reader.fieldnames)
        self.writer.writeheader()
        self.is_spdk = 0
        self.dicts = []
        for row in self.reader:
            self.dicts.append(row)


    def run_all_cases(self):
        casenum = 0
        for row in self.dicts:
            self.logger.info("run case " + str(casenum) + " " + row["casename"] + " start ......")
            runner = DBBenchRunner(casenum, row, self.OUTPUT_DIR, self.logger)
            runner.run_benchmark()
            result = runner.export_results()
            self.writer.writerow(result)
            self.wf.flush()
            self.logger.info("run case " + str(casenum) + " " + row["casename"] + " end ......")
            casenum = casenum + 1
            for key in keys[-8:]:
                print(key + ": " + result[key]);


if __name__ == "__main__":
    if len(sys.argv) < 2 or len(sys.argv) > 4:
        print("usage: " + sys.argv[0] + " [config.cvs] <enable_perf> <perf_level>")
        exit(0)
    if ENVS != None:
        os.environ[ENVS[0]]=ENVS[1]
    cur_dir = os.path.abspath(os.path.dirname(sys.argv[0]) + "/..")
    test_case_file = sys.argv[1]
    if len(sys.argv) >= 3:
        ENABLE_PERF = int(sys.argv[2]);
    if len(sys.argv) >= 4:
        PERF_LEVEL = int(sys.argv[3]);
    runner = AllCaseRunner(cur_dir, test_case_file)
    runner.run_all_cases()





