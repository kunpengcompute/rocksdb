# RocksDB 6.26.1 CRC32C Scalar-Vector Hybrid Optimization Feature Guide

<!-- md-trans-meta sourceCommit=d70fbb411c921cba0ce6bde35a94ac7ed5623923 translatedAt=2026-09-14T02:07:45.363Z pushedAt=2026-09-15T08:24:34.938Z -->

## Feature Description

### Introduction

This document describes the principle, installation, and usage of the CRC32C scalar-vector hybrid optimization feature for RocksDB 6.26.1.

RocksDB is a high-performance, embedded, and persistent key-value storage engine developed by Meta based on C++ and Log-Structured Merge-Tree (LSM-Tree), and is widely used in scenarios such as databases, cache systems, and real-time data processing.

In RocksDB, CRC32C is used to verify data integrity during writes, reads, and compactions, and its computation throughput directly affects the CPU overhead on the I/O path and in background tasks. The original Arm implementation primarily uses 3-way scalar interleaving. Although this can hide the data dependency of a single stream, it leaves vector units and some ALU ports underutilized. This optimization targets SVE2-capable AArch64 processors and introduces a hybrid pipeline that combines 10-way scalar parallelism with 8-way vector folding to improve CRC32C computation throughput.

### Principles

The original implementation interleaves crc32cx operations across three independent CRC accumulators to hide instruction latency.

This feature computes CRC32C through the coordinated use of SVE2, pmull, and crc32cx instructions, improving the computation parallelism on the AArch64 platform while ensuring that the checksum result is consistent with the original implementation. The optimized path is entered only when SVE2 is supported; if SVE2 is not supported, it automatically falls back to the original RocksDB implementation.

**CRC32C Hybrid Pipeline Optimization**

This optimization organizes the input into 416-byte blocks (10 × 16 + 8 × 32), consisting of 10 16-byte scalar lanes and 8 32-byte vector lanes. The scalar lanes use crc0 through crc9 for parallel computation, while the vector lanes use SVE2 registers and pmull to perform GF(2) polynomial folding. The results from all lanes are then reduced to a single CRC value. Scalar and vector instructions are interleaved to keep the compute, load, and multiplier units highly utilized.

In the vector folding stage, `p` constants (`x^n mod p(x)`) are used in sequence to reduce eight 256-bit intermediate results to 128 bits. The 10 scalar CRC lanes select a precomputed constant table based on the block count; when the number of blocks exceeds 1260, `xnmodp_func` is used to dynamically compute the multiplier, avoiding excessive runtime overhead. The remaining data, less than 416 bytes, is processed in 128-, 32-, 8-, 4-, 2-, and 1-byte stages, ensuring correct results for inputs of any length.

## Environment Requirements

This document provides guidance based on specific environments. Before performing operations, ensure that your hardware and software meet the requirements.

**Table 1** Hardware requirement

| Item | Description                                                |
| ------- | ---------------------------------------------------------- |
| CPU     | Kunpeng 950 processor |

**Table 2** OS and software requirements<a id="os-and-software-requirements"></a>

| Item      | Version                                                     | How to Obtain                                                     |
| ----------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| OS    | openEuler 24.03 LTS SP3                                       | [Link](https://repo.huaweicloud.com/openeuler/openEuler-24.03-LTS-SP3/ISO/aarch64/openEuler-24.03-LTS-SP3-everything-aarch64-dvd.iso) |
| RocksDB | 6.26.1                                                       | [Link](https://github.com/facebook/rocksdb/tree/v6.26.1) |
| GCC     | 12.3.1                                                   | Provided with openEuler 24.03 LTS SP3.                               |
| Java     | 11                                                        | Install it using Yum on openEuler 24.03 LTS SP3 when the network connection is normal. |
| Patch file   |            `0002_crc32c_opt.patch`                 | [Link](https://gitcode.com/boostkit/rocksdb/tree/master/src/rocksdb-6.26.1/feature-patches/0002_crc32c_opt.patch) |

## Installation Environment

To install and use this feature, you must first apply the patch file to the RocksDB source code, and then compile RocksDB.

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

   For details about how to obtain it, see [**Table 2**](#os-and-software-requirements).

4. Run the following commands to apply the optimization feature. If no command output is displayed, the patch is successfully applied.

   ```bash
   cd ~/rocksdb
   patch -p1 < ~/0002_crc32c_opt.patch
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
