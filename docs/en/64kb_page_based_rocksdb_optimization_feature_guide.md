# 64 KB Page-based RocksDB Optimization Feature Guide

## Feature Description<a name="EN-US_TOPIC_0000002512120258"></a>

### Overview<a name="EN-US_TOPIC_0000002543640185"></a>

This document describes the principles, installation, and usage of the 64 KB page-based RocksDB optimization feature.

RocksDB is a high-performance, embedded, and persistent key-value storage engine developed by Meta (formerly Facebook). It is implemented based on C++ and can be used as an embedded engine or as a storage database in client-server (C/S) mode. RocksDB uses the Log-Structured Merge-Tree (LSM-Tree) data structure to convert random writes into sequential writes, significantly improving the write throughput. This data structure is especially suitable for high-concurrency write scenarios. RocksDB also excels in point query and range query, and is widely used in scenarios such as databases, cache systems, and real-time data processing.

In the original system configuration with a 4 KB page size, RocksDB exhibits high translation lookaside buffer (TLB) cache miss rates in high-concurrency write scenarios. The 64 KB kernel page size can effectively reduce page table levels and quantities, significantly reduce the instruction TLB (ITLB) miss rates and page fault frequency, thereby improving the throughput.

### Principles<a name="EN-US_TOPIC_0000002543720175"></a>

The 64 KB page-based RocksDB optimization feature reduces TLB misses, greatly improving memory access efficiency.

The TLB is a key hardware cache in the CPU memory management unit (MMU). It stores the mapping relationships between the recently used virtual page numbers and physical frame numbers. The memory addresses referenced in program running instructions are usually virtual addresses. When the CPU accesses the actual memory (RAM), the MMU must translate these virtual addresses to physical addresses. The TLB functions as the high-speed cache of page tables. When the required mapping exists in the TLB, the CPU does not need to traverse the entire page table, thereby significantly reducing the overhead of address translation.

In an environment where the Linux kernel uses the 64 KB memory page management mechanism, RocksDB optimizes the memory alignment policy to significantly reduce TLB misses, thereby improving memory access efficiency. Specifically, RocksDB aligns the data blocks used in read and write operations with the memory page boundaries, avoiding the performance loss caused by cross-page access. This alignment also helps optimize the management efficiency of the block cache, further improving the database read and write performance.

In addition, if the jemalloc memory allocator is enabled during RocksDB compilation, ensure that the jemalloc library version in the current environment is compatible with the kernel with 64 KB page size. Therefore, you are advised to check jemalloc compatibility during the build to avoid potential operating problems caused by version mismatch. The optimization patch includes such check.

Check the current page size:

```shell
getconf PAGESIZE
```

If `4096` is displayed, the current system uses 4 KB pages and the kernel needs to be recompiled. If `65536` is displayed, the system uses 64 KB pages, indicating that the optimization feature has been enabled.

## Verified Environments<a name="EN-US_TOPIC_0000002512280240"></a>

This document provides guidance based on specific environments. Before performing operations, ensure that your hardware and software meet the requirements.

**Table 1** Hardware requirement<a id="hardware-requirement"></a>

|Item|Specifications|
|--|--|
|CPU|New Kunpeng 920 processor model or Kunpeng 950 processor|

**Table 2** OS and software requirements<a id="os-and-software-requirements"></a>

|Item|Version|How to Obtain|
|--|--|--|
|OS|openEuler 22.03 LTS SP4|[Link](https://repo.huaweicloud.com/openeuler/openEuler-22.03-LTS-SP4/ISO/aarch64/openEuler-22.03-LTS-SP4-everything-aarch64-dvd.iso)|
|OS|openEuler 24.03 LTS SP3|[Link](https://repo.huaweicloud.com/openeuler/openEuler-24.03-LTS-SP3/ISO/aarch64/openEuler-24.03-LTS-SP3-everything-aarch64-dvd.iso)|
|RocksDB|6.1.2|[Link](https://github.com/facebook/rocksdb/tree/v6.1.2)|
|GCC|10.3.1|Provided with openEuler 22.03 LTS SP4|
|Java|1.8.0|Install it using Yum on openEuler 22.03 LTS SP4 when the network connection is normal.|
|Patch file|0001-64k-jemalloc-check.patch|[Link](https://gitcode.com/boostkit/rocksdb/blob/rocksdb-v6.1.2-patch/0001-64k-jemalloc-check.patch)|

## Feature Installation and Usage<a name="EN-US_TOPIC_0000002512120260"></a>

The 64 KB page-based RocksDB optimization feature is developed for RocksDB 6.1.2 and is provided in the form of a compiled kernel and patch file. To install and use this feature, you need to recompile the 64 KB page kernel, select the compiled 64 KB page kernel after the OS restart, import the patch file, and then compile RocksDB.

1. Change the page size of the openEuler OS kernel to 64 KB and restart the OS using the kernel with 64 KB page size. For details, see [Changing the Kernel Page Size to 64 KB](https://www.hikunpeng.com/document/detail/en/kunpengdbs/ecosystemEnable/MySQL/kunpengdbstune_05_0012.html) in the *MySQL Tuning Guide*.
2. Use `git` to clone RocksDB, select version 6.1.2, and place it in the home directory `~`.

    ```shell
    cd ~
    git clone https://github.com/facebook/rocksdb.git
    cd rocksdb/
    git checkout v6.1.2
    ```

3. Install dependencies using Yum and configure environment variables.

    ```shell
    yum install -y git make gcc-c++ snappy snappy-devel zlib zlib-devel bzip2 bzip2-devel lz4 lz4-devel zstd zstd-devel java java-devel java-11-openjdk-devel gflags gflags-devel flex python maven
    
    export JAVA_HOME=/usr/lib/jvm/java-1.8.0
    export PATH=$JAVA_HOME/bin:$PATH
    ```

4. Obtain the patch file of the optimization feature and upload it to the home directory `~`. For details, see [**Table 2**](#os-and-software-requirements).
5. Apply the optimization feature patch. If no command output is displayed, the patch is successfully applied.

    ```shell
    cd ~/rocksdb
    git apply --whitespace=nowarn < ~/0001-64k-jemalloc-check.patch
    ```

6. Compile the RocksDB JAR packages and related dynamic libraries to use the optimization feature.
    1. Fix the bug in the RocksDB source code when the JAR packages and related dynamic libraries are compiled.
        1. Open the file.

            ```shell
            cd ~/rocksdb
            vim java/src/main/java/org/rocksdb/BlockBasedTableConfig.java
            ```

        2. Press `i` to enter the insert mode and change `true` to `false` in line 38.

            ```shell
            # Change true to false in line 38.
            verifyCompression = false;
            ```

        3. Press `Esc`, type `:wq!`, and press `Enter` to save the file and exit.

    2. Compile the JAR packages and related dynamic libraries of RocksDB.

        ```txt
        PORTABLE=1 DEBUG_LEVEL=0 make rocksdbjava -j`nproc` DISABLE_WARNING_AS_ERROR=1 DISABLE_JEMALLOC=1
        ```

        >![](public_sys-resources/icon-note.gif) **NOTE:**
        >As an error will be reported when the JAR packages compiled by RocksDB with jemalloc enabled are directly used, `DISABLE_JEMALLOC` is specified in the compilation options. The related checks in the patch are primarily used to control the compilation behavior of the C++ dynamic and static libraries.

    3. (Optional) If an error is reported during the compilation, indicating that JAR packages are missing, clear the files, manually download the missing JAR packages, and then perform compilation again.

        ```shell
        cd ~/rocksdb
        make clean
        mkdir -p java/test-libs
        cd java/test-libs
        wget https://repo1.maven.org/maven2/org/assertj/assertj-core/1.7.1/assertj-core-1.7.1.jar --no-check-certificate
        wget https://repo1.maven.org/maven2/cglib/cglib/2.2.2/cglib-2.2.2.jar --no-check-certificate 
        wget https://repo1.maven.org/maven2/org/mockito/mockito-all/1.10.19/mockito-all-1.10.19.jar --no-check-certificate
        wget https://repo1.maven.org/maven2/org/hamcrest/hamcrest-core/1.3/hamcrest-core-1.3.jar --no-check-certificate
        wget https://repo1.maven.org/maven2/junit/junit/4.12/junit-4.12.jar --no-check-certificate
        ```

7. (Optional) Perform the Yahoo! Cloud Serving Benchmark (YCSB) test to measure the performance improvement when the feature is enabled. For details about the test procedure, see [YCSB Test Guide](https://www.hikunpeng.com/document/detail/en/kunpengdbs/testguide/tstg/kunpengycsbformong_11_0001.html). The 64 KB page-based RocksDB optimization feature can improve the performance of workloada and workloadc by 5% on average with a configuration of 16 vCPUs. [**Figure 1**](#performance-comparison-before-and-after-the-optimization-feature-is-enabled) shows the performance comparison before and after the optimization.

    **Figure 1** Performance comparison before and after the optimization feature is enabled<a name="fig144438251669"></a><a id="performance-comparison-before-and-after-the-optimization-feature-is-enabled"></a><br>
    ![](figures/en-us_performance_comparison_64kb.png "Performance comparison before and after the optimization")

## Security Check and Hardening<a name="EN-US_TOPIC_0000002549203369"></a>

Address space layout randomization (ASLR) is a security technology against buffer overflow. It randomizes the layout of linear areas such as heap, stack, and shared library mapping to make it difficult for attackers to predict target addresses and directly locate code, thereby preventing overflow attacks.

```shell
echo 2 >/proc/sys/kernel/randomize_va_space
```

![](figures/en-us_image_0000002504021297.png)

## Change History<a name="EN-US_TOPIC_0000002543640187"></a>

|Date|Description|
|--|--|
|2026-03-30|The issue is the first official release.|
