# RocksDB 6.26.1 Bloom Filter SVE2 Vectorization-based Optimization Feature Guide

<!-- md-trans-meta sourceCommit=d70fbb411c921cba0ce6bde35a94ac7ed5623923 translatedAt=2026-09-14T02:05:10.189Z pushedAt=2026-09-15T08:23:22.993Z -->

## Feature Description

### Introduction

This document describes the principles, installation, and usage of the Bloom filter query optimization feature for RocksDB 6.26.1.

RocksDB is a high-performance, embedded, and persistent key-value storage engine developed by Meta based on C++ and Log-Structured Merge-Tree (LSM-Tree), and is widely used in scenarios such as databases, cache systems, and real-time data processing.

When RocksDB performs a lookup in an SST file, the Bloom filter first checks the bit array using the key's hash values to quickly rule out keys that cannot be present, reducing subsequent accesses to index and data blocks. The original Arm processor implementation computes and checks probe positions one by one; when the number of probes is large, this increases loop and memory-access overhead. This optimization computes and checks multiple probe positions in batches, reducing the CPU overhead of a single filter lookup.

### Principles

In the Bloom filter lookup flow, the base hash computation has already produced the initial hash value `h` for the key being queried and determined the fixed hash seed `c` used to derive subsequent hash values.

This feature leverages SVE2's parallel computation capabilities to process hash probe positions in batches instead of generating and checking them one by one, reducing redundant computation and data accesses.

When generating probe positions, the optimized implementation precomputes `c`<sup>0</sup> through `c`<sup>7</sup> and broadcasts `h` to eight 32-bit vector lanes. Each lane uses one precomputed value to generate its corresponding hash result. Therefore, a batch can produce up to eight consecutive probe positions, avoiding sequential computation in a loop.

When checking probe positions, each hash result is used to locate a target bit in a 512-bit cache line: the top 4 bits identify the target word among 16 32-bit words, and the following 5 bits determine the exact bit position within that word (bit-in-word). The system generates a 32-bit mask based on that position and checks the target bit using a bitwise AND operation. If any target bit is not set, the key being queried can be determined to be absent; if all target bits are set, the key may be present, and subsequent lookup steps must be performed.

The vectorization optimization changes only how probe positions are computed and checked; it does not change the Bloom filter's storage format, hash results, or query semantics. On platforms that support SVE2, RocksDB automatically uses vectorization; on platforms that do not support SVE2, RocksDB continues to use the original implementation, preserving compatibility.

## Environment Requirements

This document provides guidance based on specific environments. Before performing operations, ensure that your hardware and software meet the requirements.

**Table 1** Hardware requirement

| Item   | Description          |
| ------ | ------------- |
| CPU    | Kunpeng 950 processor |

**Table 2** OS and software requirements<a id="os-and-software-requirements"></a>

| Item                                            | Version                         | How to Obtain                                                                                                                          |
| ----------------------------------------------- | ---------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| OS                                        | openEuler 24.03 LTS SP3      | [Link](https://repo.huaweicloud.com/openeuler/openEuler-24.03-LTS-SP3/ISO/aarch64/openEuler-24.03-LTS-SP3-everything-aarch64-dvd.iso) |
| RocksDB                                     | 6.26.1                       | [Link](https://github.com/facebook/rocksdb/tree/v6.26.1)                                                                      |
| GCC | 12.3.1                   | Provided with openEuler 24.03 LTS SP3.                                                                                                  |
| Java  |     11             | Install it using Yum on openEuler 24.03 LTS SP3 when the network connection is normal.                                                               |
| Patch file                                        | `0003_bloomfilter_opt.patch`   | [Link](https://gitcode.com/boostkit/rocksdb/tree/master/src/rocksdb-6.26.1/feature-patches/0003_bloomfilter_opt.patch)            |

## Installation Environment

To install and use this feature, you need to first apply the patch file to the RocksDB source code and then compile RocksDB.

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

4. Run the following commands to apply the optimization feature. If no output is displayed, the patch is successfully applied.

   ```bash
   cd ~/rocksdb
   patch -p1 < ~/0003_bloomfilter_opt.patch
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
