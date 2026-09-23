# RocksDB 6.26.1 Dynamic Level Capacity Optimization Feature Guide

<!-- md-trans-meta sourceCommit=d70fbb411c921cba0ce6bde35a94ac7ed5623923 translatedAt=2026-09-14T02:10:18.298Z pushedAt=2026-09-15T08:25:51.481Z -->

## Feature Description

### Introduction

This document describes the principles, installation, and usage of the dynamic level capacity optimization feature for RocksDB 6.26.1.  
The original level compaction in RocksDB uses a fixed level capacity growth ratio. Under continuously growing data volumes and mixed read/write workloads, this strategy may increase the number of levels that queries need to access, and immediately trigger compaction when a new level is enabled, causing extra I/O overhead and affecting read/write performance. The dynamic level capacity optimization feature dynamically adjusts the capacity ratio per level, expands the amount of data that deeper levels can hold, and reduces the number of levels that queries need to access as well as unnecessary compaction, thereby lowering read/write amplification and improving read/write performance. This feature does not change the MemTable, WAL, or SST file formats.

### Principles

The traditional Log-Structured Merge-Tree (LSM-Tree) design mainly targets high-throughput write operations, but suffers from low read efficiency, especially for range queries. This feature introduces a new strategy that dynamically adjusts the capacity ratio between adjacent levels to increase the capacity of deeper levels, thereby reducing the number of I/O operations required by queries. In a traditional LSM-Tree, the capacity of each level increases by a constant factor `T`. This optimization introduces an additional scaling factor `c` (`c` < 1). With this strategy, the capacity of deeper levels can gradually increase, reducing the number of levels that queries must access and lowering query complexity. In addition, when a level reaches its capacity limit, the traditional strategy introduces a new level and immediately triggers compaction. With this optimization, when a new level is introduced, the previous level has already grown large enough to hold all current data. Therefore, no immediate compaction is required, which also improves write performance.

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
| Patch file | `0004_dynamic_capacity_opt.patch` | [Link](https://gitcode.com/boostkit/rocksdb/tree/master/src/rocksdb-6.26.1/feature-patches) |

## Feature Installation and Usage

The RocksDB dynamic level capacity optimization feature is developed for RocksDB 6.26.1 and is provided as a patch file. To install and use this feature, apply the patch file to the RocksDB source code and then compile RocksDB.

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

3. Obtain the patch file of the optimization feature and upload it to the `$HOME` directory.

   For details about how to obtain the patch file, see [Table 2](#os-and-software-requirements).

4. Run the following commands to apply the dynamic level capacity optimization feature. If no output is displayed, the patch is successfully applied.

   ```bash
   cd $HOME/rocksdb
   patch -p1 < 0004_dynamic_capacity_opt.patch
   ```

5. Compile the RocksDB JAR packages and related dynamic libraries to use the dynamic level capacity optimization feature.

   1. Compile the JAR packages and related dynamic libraries of RocksDB.

      ```bash
      make clean
      PORTABLE=1 DEBUG_LEVEL=0 make rocksdbjava -j$nproc DISABLE_WARNING_AS_ERROR=1 DISABLE_JEMALLOC=1
      ```

   2. Replace the JAR package in the local Maven repository.

      ```bash
      cd $HOME/rocksdb
      cp java/target/rocksdbjni-6.26.1-linux64.jar \
         ~/.m2/repository/org/rocksdb/rocksdbjni/6.26.1/rocksdbjni-6.26.1.jar
      cp java/target/rocksdbjni-6.26.1-linux64.jar.sha1 \
         ~/.m2/repository/org/rocksdb/rocksdbjni/6.26.1/rocksdbjni-6.26.1.jar.sha1
      ```

6. Run the YCSB test to verify whether the dynamic level capacity optimization feature takes effect.

   The combination of five features—prefetch optimization, CRC32 optimization, Bloom filter lookup optimization, dynamic level capacity optimization, and index block HashSearch optimization—yields an average 10% performance improvement across YCSB workloads a to f. [Figure 1](#performance-comparison-before-and-after-enabling-the-five-features) shows the performance comparison before and after optimization.

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
