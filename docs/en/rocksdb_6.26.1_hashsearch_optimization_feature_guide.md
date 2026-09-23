# RocksDB HashSearch Optimization Feature Guide

<!-- md-trans-meta sourceCommit=d70fbb411c921cba0ce6bde35a94ac7ed5623923 translatedAt=2026-09-14T02:15:11.176Z pushedAt=2026-09-15T08:33:13.642Z -->

## Feature Description

### Introduction

This document describes the principles, installation, and usage of the index block HashSearch optimization feature for RocksDB.

RocksDB is a high-performance, embedded, and persistent key-value storage engine developed by Meta (formerly Facebook). It is implemented based on C++ and can be used as an embedded engine or as a storage database in client-server (C/S) mode. RocksDB uses the Log-Structured Merge-Tree (LSM-Tree) data structure to convert random writes into sequential writes, significantly improving the write throughput. This data structure is especially suitable for high-concurrency write scenarios. RocksDB also excels in point query and range query, and is widely used in scenarios such as databases, cache systems, and real-time data processing.

When RocksDB looks up records in SST files, the efficiency of HashSearch in locating the candidate data block range directly affects drive I/O and CPU overhead. Although traditional HashSearch can narrow the search range by using key prefixes, it may fail to reliably take the HashSearch path when the prefix configuration changes, metadata parsing semantics are inconsistent, or block entry parsing overhead is high, causing it to fall back to a binary search over the entire index block. By optimizing prefix configuration matching, HashSearch metadata loading, and block parsing, RocksDB can more reliably use the existing prefix hash information in SST files to narrow the candidate range, reduce unnecessary index block comparisons and data block reads, and combine AArch64-specific parsing acceleration to lower hot-path CPU overhead, thereby improving query performance in high-concurrency read scenarios to some extent.

### Principles

By optimizing the HashSearch query path, this feature narrows the candidate data block search range for the target key, reduces invalid index block comparisons and drive I/O, and improves the overall query performance and system stability of RocksDB on Kunpeng 950 servers.

In RocksDB, HashSearch is used to quickly locate the candidate index block entries and data blocks that may contain the target record based on the key prefix, reducing invalid index block comparisons and unnecessary drive I/O. Because query operations frequently pass through this path, the accuracy of candidate range locating, the reliability of metadata parsing, and the underlying parsing efficiency are particularly critical.

While ensuring query correctness and SST file format compatibility, this feature provides targeted optimizations to the HashSearch read path. For scenarios involving prefix configuration changes, HashSearch metadata loading, and block parsing overhead, the optimization maintains stable prefix rules across different SST files and determines at query time whether the current configuration can safely use HashSearch. When the configuration matches, it narrows the candidate data block range; when it does not, it automatically falls back to regular binary search, avoiding missed lookups caused by incorrectly narrowing the range. In addition, it optimizes block parsing to reduce memory-access and computation overhead on hot paths, balancing performance and stability. This optimization strikes a balance among HashSearch query performance, configuration compatibility, and safe fallback, improving query throughput in high-concurrency read scenarios on Kunpeng servers.

## Verified Environments

This document provides guidance based on specific environments. Before performing operations, ensure that your hardware and software meet the requirements.

**Table 1** Hardware requirement

|Item|Specification|
|--|--|
|CPU|Kunpeng 950 processor|

**Table 2** OS and software requirements<a id="os-and-software-requirements"></a>

|Item|Version|How to Obtain|
|--|--|--|
|OS| openEuler 24.03 LTS SP3|[Link](https://repo.huaweicloud.com/openeuler/openEuler-24.03-LTS-SP3/ISO/aarch64/openEuler-24.03-LTS-SP3-everything-aarch64-dvd.iso)|
|RocksDB|6.26.1| [Link](https://github.com/facebook/rocksdb/tree/v6.26.1) |
|GCC|12.3.1|Provided with openEuler 24.03 LTS SP3.|
|Java|11|Install it using Yum on openEuler 24.03 LTS SP3 when the network connection is normal.|
|Patch file|`0005_fix_hashsearch_problem.patch`|[Link](https://gitcode.com/boostkit/rocksdb/tree/master/src/rocksdb-6.26.1/feature-patches/0005_fix_hashsearch_problem.patch)|

## Feature Installation and Usage

The RocksDB index block HashSearch optimization feature is developed for RocksDB 6.26.1 and is provided as a patch file. To install and use this feature, apply the patch file to the RocksDB source code and then compile RocksDB.

1. Use Git to clone RocksDB, switch to version 6.26.1, and place it in the home directory `~`.

   ```shell
   cd ~
   git clone https://github.com/facebook/rocksdb.git
   cd rocksdb/
   git checkout v6.26.1
   ```

2. Install dependencies using Yum and configure environment variables.

   ```shell
   yum install -y git make gcc-c++ snappy snappy-devel zlib zlib-devel bzip2 bzip2-devel lz4 lz4-devel zstd zstd-devel java java-devel java-11-openjdk-devel gflags gflags-devel flex python maven
   
   export JAVA_HOME=/usr/lib/jvm/java-11
   export PATH=$JAVA_HOME/bin:$PATH
   ```

3. Obtain the patch file of the optimization feature and upload it to the home directory `~`.

   For details about how to obtain the patch, see [**Table 2**](#os-and-software-requirements).

4. Run the following commands to apply the optimization feature. If no output is displayed, the patch is successfully applied.

   ```shell
   cd ~/rocksdb
   patch -p1 < ~/0005_fix_hashsearch_problem.patch
   ```

5. Compile the RocksDB JAR packages and related dynamic libraries to use the optimization feature.

   1. Compile the JAR packages and related dynamic libraries of RocksDB.

      ```shell
      make clean
      PORTABLE=1 DEBUG_LEVEL=0 make rocksdbjava -j`nproc` DISABLE_WARNING_AS_ERROR=1 DISABLE_JEMALLOC=1
      ```

   2. (Optional) If an error is reported during the compilation, indicating that JAR packages are missing, clear the files, manually download the missing JAR packages, and then perform compilation again.

      ```shell
      cd ~/rocksdb
      make clean
      mkdir -p java/test-libs
      cd java/test-libs
      wget https://repo1.maven.org/maven2/org/assertj/assertj-core/2.9.0/assertj-core-2.9.0.jar --no-check-certificate
      wget https://repo1.maven.org/maven2/cglib/cglib/3.3.0/cglib-3.3.0.jar --no-check-certificate 
      wget https://repo1.maven.org/maven2/org/mockito/mockito-all/1.10.19/mockito-all-1.10.19.jar --no-check-certificate
      wget https://repo1.maven.org/maven2/org/hamcrest/hamcrest-core/2.2/hamcrest-core-2.2.jar --no-check-certificate
      wget https://repo1.maven.org/maven2/junit/junit/4.13.1/junit-4.13.1.jar --no-check-certificate
      ```

   3. Replace the JAR package in the local Maven repository.

      ```shell
      cd ~/rocksdb
      cp java/target/rocksdbjni-6.26.1-linux64.jar \
         ~/.m2/repository/org/rocksdb/rocksdbjni/6.26.1/rocksdbjni-6.26.1.jar
      cp java/target/rocksdbjni-6.26.1-linux64.jar.sha1 \
         ~/.m2/repository/org/rocksdb/rocksdbjni/6.26.1/rocksdbjni-6.26.1.jar.sha1
      ```

   4. Extract the native dynamic library and set `LD_LIBRARY_PATH`.

      ```shell
      # Create the library storage directory (for YCSB).
      mkdir -p ~/Test/rocksdb-lib
      # Clear old files.
      rm -f ~/Test/rocksdb-lib/*
      # Extract the .so file.
      unzip -jo ~/.m2/repository/org/rocksdb/rocksdbjni/6.26.1/rocksdbjni-6.26.1.jar "*.so" -d ~/Test/rocksdb-lib
      # Verify the .so file.
      ls -lh ~/Test/rocksdb-lib/
      # Set the environment variable.
      export LD_LIBRARY_PATH=~/Test/rocksdb-lib:$LD_LIBRARY_PATH
      ```

      Note: Modify the preceding paths and files based on the actual situation.  
6. Run the YCSB test to verify whether the HashSearch optimization feature takes effect.
      The combination of five features—prefetch optimization, CRC32 optimization, Bloom filter lookup optimization, dynamic level capacity optimization, and index block HashSearch optimization—yields an average 10% performance improvement across YCSB workloads a to f under a 16-vCPU configuration. [Figure 1](#performance-comparison-before-and-after-enabling-the-five-features) shows the performance comparison before and after optimization.

      **Figure 1** Performance comparison before and after enabling the five features<a id="performance-comparison-before-and-after-enabling-the-five-features"></a>  
      <img src="figures/performance-comparison-features-combined.png" alt="Performance comparison before and after enabling the five features" style="zoom:40%;" />

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
