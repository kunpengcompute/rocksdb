# RocksDB 6.26.1 GCC Compilation Optimization Feature Guide

<!-- md-trans-meta sourceCommit=d70fbb411c921cba0ce6bde35a94ac7ed5623923 translatedAt=2026-09-14T02:12:38.067Z pushedAt=2026-09-15T06:36:56.504Z -->

## Feature Description

### Introduction

This document describes the method, environment requirements, and verification process for enabling the GCC compilation optimization feature for RocksDB via build script parameters.
As an embedded key-value storage engine, RocksDB has execution hotspots that vary with the read/write ratio, data access distribution, and request types of the upper-layer workload. Static compilation alone cannot accurately reflect these differences. Runtime information therefore needs to be collected under representative workloads so that the compiler can optimize code generation around the actual hotspots.  The GCC compilation optimization feature uses compiler options to change the optimization level or architecture-specific instructions for object files and final output.

### Principles

RocksDB is optimized at compile time using GCC PGO. During service testing, RocksDB's function execution counts and branch information are collected, and RocksDB is then rebuilt using the generated profile (profiling data). Based on this, GCC identifies the hot paths under the current workload and adjusts compilation decisions such as function inlining, branch prediction, code layout, and loop optimization.
RocksDB's compilation process consists of three stages: instrumented build, workload testing, and feedback-based build. First, an instrumented version of RocksDB is built with `-fprofile-generate`. Then, workload tests are run, writing information such as function execution counts and branch outcomes to a specified profile directory. The read/write ratio, data scale, and access distribution of the test workload are used to simulate the target workload's access pattern. The generated profile therefore reflects the function hotspots and branch behavior under that workload.
Finally, an optimized version of RocksDB is rebuilt using the generated profile with the `-fprofile-use` option.

## Verified Environments

This document provides guidance based on specific environments. Before performing operations, ensure that your hardware and software meet the requirements.

**Table 1** Hardware requirement

| Item | Specification |
| ---- | ---- |
| CPU | Kunpeng 950 processor |

**Table 2** OS and software requirements<a id="os-and-software-requirements"></a>

| Item | Requirement | How to Obtain |
| ----------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| OS | openEuler 24.03 LTS SP3 | [Link](https://repo.huaweicloud.com/openeuler/openEuler-24.03-LTS-SP3/ISO/aarch64/openEuler-24.03-LTS-SP3-everything-aarch64-dvd.iso) |
| GCC | 12.3.1 | Provided with openEuler 24.03 LTS SP3. |
| JDK | 11 | Install it using Yum on openEuler 24.03 LTS SP3 when the network connection is normal. |
| RocksDB | 6.26.1 | [Link](https://github.com/facebook/rocksdb/tree/v6.26.1) |
| Optimization feature patches | Patches `0001` to `0005` | [Link](https://gitcode.com/boostkit/rocksdb/tree/master/src/rocksdb-6.26.1/feature-patches) |

## Feature Installation and Usage

1. Use Git to clone RocksDB, switch to version 6.26.1, and place it in the `$HOME` directory.

   ```bash
   cd $HOME
   git clone https://github.com/facebook/rocksdb.git
   cd rocksdb/
   git checkout v6.26.1
   ```

2. Install dependencies using Yum and configure environment variables.

   ```bash
   yum install -y git make gcc-c++ snappy snappy-devel zlib zlib-devel bzip2 bzip2-devel lz4 lz4-devel zstd zstd-devel java java-devel java-11-openjdk-devel gflags gflags-devel flex python maven

   export JAVA_HOME=/usr/lib/jvm/java-11
   export PATH=$JAVA_HOME/bin:$PATH
   ```

3. (Optional) Obtain the patch files for the optimization feature and upload them to the `$HOME` directory.

   For details about how to obtain the patches, see [Table 2](#os-and-software-requirements).

4. (Optional) Go to the `$HOME/rocksdb` directory and apply the `0001` to `0005` patches in sequence according to the actual file names in the `feature-patches` directory. If no output is displayed, the patches are applied successfully.

5. Compile the RocksDB JAR packages and related dynamic libraries to use the GCC compilation optimization feature.

   1. Compile the JAR packages and related dynamic libraries of RocksDB.

      ```bash
      cd "$HOME/rocksdb"
      make clean
      PORTABLE=1 DEBUG_LEVEL=0 make rocksdbjava -j$nproc DISABLE_WARNING_AS_ERROR=1 DISABLE_JEMALLOC=1
      ```

   2. Replace the JAR package in the local Maven repository.

      ```bash
      cd "$HOME/rocksdb"
      cp java/target/rocksdbjni-6.26.1-linux64.jar \
         "~/.m2/repository/org/rocksdb/rocksdbjni/6.26.1/rocksdbjni-6.26.1.jar"
      cp java/target/rocksdbjni-6.26.1-linux64.jar.sha1 \
         "~/.m2/repository/org/rocksdb/rocksdbjni/6.26.1/rocksdbjni-6.26.1.jar.sha1"
      ```

6. Enable the GCC compilation optimization feature for RocksDB.

   1. Recompile RocksDB with instrumentation.

      ```bash
      #!/bin/bash
      WORKSPACE=$HOME
      OPT_FLAGS="-O3 -flto -fprofile-generate=$WORKSPACE/pgo -fno-plt -fprofile-update=single -fprofile-partial-training -Wno-error=coverage-mismatch -Wno-error=missing-profile -fprofile-correction"

      export JAVA_HOME=/usr/lib/jvm/java-11
      export PATH=$JAVA_HOME/bin:$PATH
      cd $WORKSPACE/rocksdb
      export EXTRA_CFLAGS=${OPT_FLAGS}
      export EXTRA_CXXFLAGS=${OPT_FLAGS}
      export EXTRA_LDFLAGS=${OPT_FLAGS}
      export OPTIMIZE_LEVEL="-O3"

      make clean
      PORTABLE=1 DEBUG_LEVEL=0 make rocksdbjava -j$nproc DISABLE_WARNING_AS_ERROR=1 DISABLE_JEMALLOC=1

      cp java/target/rocksdbjni-6.26.1-linux64.jar \
         "$HOME/.m2/repository/org/rocksdb/rocksdbjni/6.26.1/rocksdbjni-6.26.1.jar"
      cp java/target/rocksdbjni-6.26.1-linux64.jar.sha1 \
         "$HOME/.m2/repository/org/rocksdb/rocksdbjni/6.26.1/rocksdbjni-6.26.1.jar.sha1"
      ```

   2. Run stress tests for profiling. Take YCSB as an example: run performance benchmarks for workloads a to f consecutively on pre-warmed data. The instrumented build is slower at runtime. After it completes, verify that the profiling data files have been generated in the directory specified by `-fprofile-generate`.

      ```bash
      cd "$HOME/YCSB_RUN/YCSB_RUN/ycsb-rocksdb-binding-0.18.0-SNAPSHOT"

      taskset -c 0-15 ./bin/ycsb run rocksdb -s \
      -P workloads/workloada \
      -p fieldlength=256 -p fieldcount=1 \
      -p recordcount=100000000 -p operationcount=100000000 \
      -p rocksdb.dir="$HOME/data/workload_data/" \
      -p rocksdb.optionsfile="$HOME/data/configs/dbsnappyrun.ini" \
      -p rocksdb.cfs=default -p table=default -threads 5
      ```

   3. Recompile the optimized version of RocksDB.

      Replace `-fprofile-generate` in the instrumented compilation script with `-fprofile-use`, and recompile the optimized version based on the profile data.

      ```bash
      #!/bin/bash
      WORKSPACE=$HOME
      OPT_FLAGS="-O3 -flto -fprofile-use=$WORKSPACE/pgo -fno-plt -fprofile-update=single -fprofile-partial-training -Wno-error=coverage-mismatch -Wno-error=missing-profile -fprofile-correction"

      export JAVA_HOME=/usr/lib/jvm/java-11
      export PATH=$JAVA_HOME/bin:$PATH
      cd $WORKSPACE/rocksdb
      export EXTRA_CFLAGS=${OPT_FLAGS}
      export EXTRA_CXXFLAGS=${OPT_FLAGS}
      export EXTRA_LDFLAGS=${OPT_FLAGS}
      export OPTIMIZE_LEVEL="-O3"

      make clean
      PORTABLE=1 DEBUG_LEVEL=0 make rocksdbjava -j$nproc DISABLE_WARNING_AS_ERROR=1 DISABLE_JEMALLOC=1

      cp java/target/rocksdbjni-6.26.1-linux64.jar \
         "$HOME/.m2/repository/org/rocksdb/rocksdbjni/6.26.1/rocksdbjni-6.26.1.jar"
      cp java/target/rocksdbjni-6.26.1-linux64.jar.sha1 \
         "$HOME/.m2/repository/org/rocksdb/rocksdbjni/6.26.1/rocksdbjni-6.26.1.jar.sha1"
      ```

7. Run the performance test. Take YCSB as an example.

   ```bash
   # Delete the current loaded data directory, restore the backup data, and run the stress test again
   rm -rf $HOME/data/workload_data/
   cp -r $HOME/data/workload_data_backup $HOME/data/workload_data/

   cd "$HOME/YCSB_RUN/YCSB_RUN/ycsb-rocksdb-binding-0.18.0-SNAPSHOT"

   taskset -c 0-15 ./bin/ycsb run rocksdb -s \
   -P workloads/workloada \
   -p fieldlength=256 -p fieldcount=1 \
   -p recordcount=100000000 -p operationcount=100000000 \
   -p rocksdb.dir="$HOME/data/workload_data/" \
   -p rocksdb.optionsfile="$HOME/data/configs/dbsnappyrun.ini" \
   -p rocksdb.cfs=default -p table=default -threads 5
   ```

   The combined use of GCC compilation optimization and memory allocation optimization yields an average 10% performance improvement across YCSB benchmark workloads a to f. [Figure 1](#performance-comparison-before-and-after-enabling-the-two-features) shows the comparison before and after optimization.

   **Figure 1** Performance comparison before and after enabling the two features<a id="performance-comparison-before-and-after-enabling-the-two-features"></a>

   <img src="figures/performance-comparison-features-combined.png" alt="Performance comparison before and after enabling the two features" style="zoom:40%;" />

## Security Check and Hardening

Address space layout randomization (ASLR) is a security technology against buffer overflow. It randomizes the layout of linear areas such as heap, stack, and shared library mapping to make it difficult for attackers to predict target addresses and directly locate code, thereby preventing overflow attacks.

```bash
echo 2 > /proc/sys/kernel/randomize_va_space
cat /proc/sys/kernel/randomize_va_space
```

![](figures/en-us_image_0000002504021297.png)

## Change History

|Version| Date   | Description         |
|----------| ---------- | ---------------- |
|01| 2026-09-30 | This is the first official release. |
