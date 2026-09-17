# RocksDB 6.26.1动态Level容量优化 特性指南

## 特性描述

### 简介

本文主要介绍RocksDB 6.26.1动态Level容量优化特性的原理、安装和使用方法。
RocksDB原有的Level compaction使用固定的层级容量增长比例。在数据规模持续增长以及读写混合负载下，该策略可能增加查询需要访问的层级数量，并在启用新层级时立即触发compaction，导致额外的I/O开销，影响读写性能。动态Level容量优化特性根据层级动态调整容量比例，扩大底层可容纳的数据量，减少查询需要访问的层级及不必要的compaction，从而降低读放大和写放大，改善读写性能。该特性不改变MemTable、WAL或SST文件格式。

### 原理描述

传统LSM-tree的设计主要针对高吞吐量的写操作，但其读取效率较低，尤其是在范围查询方面。本特性引入了一种新的合并策略，通过动态调整相邻层之间的容量比，增加底层的容量，从而减少查询所需I/O次数。在传统LSM-tree中，每个层级容量以一个常量T递增，本优化策略引入一个额外放缩因子c（c<1），通过该优化策略可以使底层的容量逐渐增加，减少查询过程中需要访问的层级数量，降低查询复杂度。此外，当容量达到限制时，在传统策略下会使用新的层级并且立即触发compaction，而采用该优化策略后，当使用新层级的时候，旧层级的容量已经变大并且足够存储当前的所有数据，因此无需立即触发compaction，从而对写入性能也有优化效果。

## 已验证环境

本文基于特定环境提供指导，在正式操作前请确保软硬件均满足要求。

**表1** 硬件要求

| 项目 | 规格 |
| ---- | ---- |
| CPU | 鲲鹏950处理器 |

**表2** 操作系统和软件要求<a id="操作系统和软件要求"></a>

| 项目 | 版本 | 获取地址 |
| --- | --- | --- |
| 操作系统 | openEuler 24.03 LTS SP3 | [获取链接](https://repo.huaweicloud.com/openeuler/openEuler-24.03-LTS-SP3/ISO/aarch64/openEuler-24.03-LTS-SP3-everything-aarch64-dvd.iso) |
| 操作系统 | openEuler 22.03 LTS SP4 | [获取链接](https://repo.huaweicloud.com/openeuler/openEuler-22.03-LTS-SP4/ISO/aarch64/openEuler-22.03-LTS-SP4-everything-aarch64-dvd.iso) |
| RocksDB | 6.26.1 | [获取链接](https://github.com/facebook/rocksdb/tree/v6.26.1) |
| GCC | 12.3.1（24.03 LTS SP3） | 通过yum源安装 |
| GCC | 12.3.1（22.03 LTS SP4） | [获取链接](https://mirrors.huaweicloud.com/kunpeng/archive/compiler/kunpeng_gcc/gcc-12.3.1-2025.06-aarch64-linux.tar.gz) |
| Java | 11 | 通过yum源安装 |
| 动态Level容量优化patch | 0004_dynamic_capacity_opt.patch | [获取链接](https://gitcode.com/boostkit/rocksdb/tree/master/src/rocksdb-6.26.1/feature-patches) |

## 安装和使用特性

RocksDB动态Level容量优化特性针对RocksDB 6.26.1版本进行开发，以patch文件形式提供。安装和使用该特性需先在RocksDB源码中应用该patch文件，再编译RocksDB。

1. 使用git克隆RocksDB并切换到6.26.1版本，放在$HOME目录下。

   ```bash
   cd $HOME
   git clone https://github.com/facebook/rocksdb.git
   cd rocksdb/
   git checkout v6.26.1
   ```

2. 下载并安装GCC 12.3.1编译器。

   ```bash
   cd ~
   wget https://mirrors.huaweicloud.com/kunpeng/archive/compiler/kunpeng_gcc/gcc-12.3.1-2025.06-aarch64-linux.tar.gz
   tar -zxvf gcc-12.3.1-2025.06-aarch64-linux.tar.gz
   
   export PATH=~/gcc-12.3.1-2025.06-aarch64-linux/bin:$PATH
   export LD_LIBRARY_PATH=~/gcc-12.3.1-2025.06-aarch64-linux/lib64:$LD_LIBRARY_PATH
   export INCLUDE=~/gcc-12.3.1-2025.06-aarch64-linux/include:$INCLUDE
   ```

3. 安装yum依赖和配置环境变量。

   ```bash
   yum install -y git make snappy snappy-devel zlib zlib-devel bzip2 bzip2-devel lz4 lz4-devel zstd zstd-devel java java-devel java-11-openjdk-devel gflags gflags-devel flex python maven

   export JAVA_HOME=/usr/lib/jvm/java-11
   export PATH=$JAVA_HOME/bin:$PATH
   ```

4. 获取优化特性的补丁文件，将其上传到$HOME目录下。

   获取路径请参见[表2操作系统和软件要求](#操作系统和软件要求)。

5. 执行以下命令，合入动态Level容量优化特性。如果没有输出则说明合入成功。

   ```bash
   cd $HOME/rocksdb
   patch -p1 < 0004_dynamic_capacity_opt.patch
   ```

6. 编译RocksDB的jar包和相关动态库，以使用动态Level容量优化特性。

   1. 编译RocksDB的jar包和相关动态库。

      ```bash
      make clean
      PORTABLE=1 DEBUG_LEVEL=0 make rocksdbjava -j$nproc DISABLE_WARNING_AS_ERROR=1 DISABLE_JEMALLOC=1
      ```

   2. 替换本地Maven仓库中的jar包。

      ```bash
      cd $HOME/rocksdb
      cp java/target/rocksdbjni-6.26.1-linux64.jar \
         ~/.m2/repository/org/rocksdb/rocksdbjni/6.26.1/rocksdbjni-6.26.1.jar
      cp java/target/rocksdbjni-6.26.1-linux64.jar.sha1 \
         ~/.m2/repository/org/rocksdb/rocksdbjni/6.26.1/rocksdbjni-6.26.1.jar.sha1
      ```

7. 执行YCSB测试，验证动态Level容量优化特性是否生效。

   Prefetch预取优化、CRC32优化、BloomFilter查找优化、动态Level容量优化、Index Block Hash Search优化五特性叠加使用后，YCSB测试工具workload a-f的性能平均提升10%，优化前后对比效果如[五特性叠加使能前后性能对比](#五特性叠加使能前后性能对比)所示。

   **图1** 五特性叠加使能前后性能对比<a id="五特性叠加使能前后性能对比"></a>

   ![五特性叠加使能前后性能对比](figures/五特性叠加使能前后性能对比.png)

## 安全检查与加固

ASLR（Address Space Layout Randomization，地址空间布局随机化）是一种针对缓冲区溢出的安全保护技术，通过对堆、栈、共享库映射等线性区布局的随机化，增加攻击者预测目的地址的难度，防止攻击者直接定位攻击代码位置，达到阻止溢出攻击的目的。

```bash
echo 2 > /proc/sys/kernel/randomize_va_space
cat /proc/sys/kernel/randomize_va_space
```

![ASLR安全检查示意图](figures/zh-cn_image_0000002504021297.png)

## 修订记录

|文档版本| 发布日期   | 修改说明         |
|----------| ---------- | ---------------- |
|01| 2026-09-30 | 第一次正式发布。 |
