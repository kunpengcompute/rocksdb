# RocksDB 6.26.1 MemTable Skip List and SST Block Prefetch Optimization Feature Guide

<!-- md-trans-meta sourceCommit=d70fbb411c921cba0ce6bde35a94ac7ed5623923 translatedAt=2026-09-14T02:20:46.985Z pushedAt=2026-09-15T07:26:31.912Z -->

## Feature Description

### Introduction

This document describes the principles, installation, and usage of the prefetch optimization feature for RocksDB 6.26.1.

RocksDB is a high-performance, embedded, and persistent key-value storage engine developed by Meta based on C++ and Log-Structured Merge-Tree (LSM-Tree), and is widely used in scenarios such as databases, cache systems, and real-time data processing.

In RocksDB, during lookups in the MemTable skip list and SST blocks, pointer chasing, restart offset reading, and key decoding can all cause cache misses, leaving the CPU stalled waiting for memory. The original implementation prefetches data likely to be accessed next, but only on some paths. As a result, it cannot cover subsequent accesses during level descent, sequential scans, or binary-search branches. Depending on the lookup level and branch, this optimization prefetches the next-level node, the same-level successor, and the midpoints of the left and right subintervals while comparing the current key, thereby hiding memory access latency as much as possible and improving throughput in read-intensive workloads.

### Principles

This feature issues cache prefetch instructions before the data is actually used, overlapping memory accesses with computation phases such as key comparison and restart-point binary search, thereby reducing stalls caused by cache misses.

**Skip List Pointer Chasing Optimization**

After accessing the current node, the optimization prefetches both `x->Next(level - 1)` and `next->Next(level)`. The former prepares the first candidate node at the lower level for descending after a failed comparison, while the latter prepares the next-next node for continued traversal at the same level. During the current key comparison, the memory subsystem can fetch the data at these addresses in parallel.

**Block Lookup Prefetch Optimization**

At the start of the binary search within a block, the optimization prefetches the initial midpoint. During a sequential scan, it prefetches the next key. On each comparison, it computes and prefetches the midpoints of the left and right subintervals at the same time. Whether the next iteration goes left or right, the candidate restart offset has a chance to be brought into the cache ahead of time, reducing additional misses caused by the branch direction.

Prefetching applies to random `Get`, `Seek`, range-query starting-point lookups, and MemTable lookups that miss the cache.

## Environment Requirements

This document provides guidance based on specific environments. Before performing operations, ensure that your hardware and software meet the requirements.

**Table 1** Hardware requirement

| Item | Description                                                |
| ---- | --------------------------------------------------- |
| CPU  | Kunpeng 950 processor |

**Table 2** OS and software requirements<a id="os-and-software-requirements"></a>

| Item      | Version                                                     | How to Obtain                                                     |
| ----------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| OS    | openEuler 24.03 LTS SP3                                       | [Link](https://repo.huaweicloud.com/openeuler/openEuler-24.03-LTS-SP3/ISO/aarch64/openEuler-24.03-LTS-SP3-everything-aarch64-dvd.iso) |
| RocksDB | 6.26.1                                                       | [Link](https://github.com/facebook/rocksdb/tree/v6.26.1) |
| GCC     | 12.3.1                                                   | Provided with openEuler 24.03 LTS SP3.                               |
| Java     |  11                                                        | Install it using Yum on openEuler 24.03 LTS SP3 when the network connection is normal. |
| Patch file   |          `0001_prefetch_opt.patch`                   | [Link](https://gitcode.com/boostkit/rocksdb/tree/master/src/rocksdb-6.26.1/feature-patches/0001_prefetch_opt.patch) |

## Installation Environment

To install and use this feature, you must first apply the patch file to the RocksDB source code and then compile RocksDB.

1. Use Git to clone RocksDB, switch to version 6.26.1, and place it in the home directory `~`.

   ```bash
   cd ~
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

3. Obtain the patch file of the optimization feature and upload it to the home directory `~`.

   For details about how to obtain the patch, see [**Table 2**](#os-and-software-requirements).

4. Run the following commands to apply the optimization feature. If no command output is displayed, the patch is successfully applied.

   ```bash
   cd ~/rocksdb
   patch -p1 < ~/0001_prefetch_opt.patch
   ```

5. Compile the RocksDB JAR packages and related dynamic libraries to use the optimization feature.

   1. Compile the JAR packages and related dynamic libraries of RocksDB.

      ```bash
      make clean
      PORTABLE=1 DEBUG_LEVEL=0 make rocksdbjava -j`nproc` DISABLE_WARNING_AS_ERROR=1 DISABLE_JEMALLOC=1
      ```

   2. (Optional) If an error is reported during the compilation, indicating that JAR packages are missing, clear the files, manually download the missing JAR packages, and then perform compilation again.

      ```bash
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

      ```bash
      cd ~/rocksdb
      cp java/target/rocksdbjni-6.26.1-linux64.jar \
         ~/.m2/repository/org/rocksdb/rocksdbjni/6.26.1/rocksdbjni-6.26.1.jar
      cp java/target/rocksdbjni-6.26.1-linux64.jar.sha1 \
         ~/.m2/repository/org/rocksdb/rocksdbjni/6.26.1/rocksdbjni-6.26.1.jar.sha1
      ```

   4. Extract the native dynamic library and set `LD_LIBRARY_PATH`.

      ```bash
      # Create the library storage directory (for YCSB use).
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

6. (Optional) Use the YCSB tool to test the performance improvement after enabling this feature.

With this prefetch optimization feature, performance can be improved by about 4% on average.

## Security Check and Hardening

Address space layout randomization (ASLR) is a security technology against buffer overflow. It randomizes the layout of linear areas such as heap, stack, and shared library mapping to make it difficult for attackers to predict target addresses and directly locate code, thereby preventing overflow attacks.

```bash
echo 2 | sudo tee /proc/sys/kernel/randomize_va_space
cat /proc/sys/kernel/randomize_va_space
```

![](figures/en-us_image_0000002504021297.png)

## Change History

|Version| Date   | Description         |
|----------| ---------- | ---------------- |
|01| 2026-09-30 | This is the first official release. |
