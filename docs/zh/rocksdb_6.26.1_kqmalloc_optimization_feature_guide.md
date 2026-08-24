# RocksDB 6.26.1内存分配优化 特性指南

## 特性描述

### 简介

本文介绍RocksDB数据库通过`kqmalloc`内存分配器进行内存分配优化的方法、环境要求及验证流程。
RocksDB作为嵌入式键值存储引擎，读写、缓存、memtable、flush、compaction等操作会频繁申请和释放内存，容易在分配路径上产生额外开销和并发竞争。因此需要降低内存分配成本，并改善并发场景下的内存管理效率。
本特性不修改RocksDB业务代码，通过脚本和链接配置切换进程的内存分配库。可以单独使用该特性，也可与GCC编译优化特性组合使用。

### 原理描述

RocksDB作为嵌入式键值存储引擎，在上层应用或测试程序的进程内运行。内存分配优化特性使用kqmalloc多线程动态库替换该进程的默认内存分配器，覆盖RocksDB在读写、缓存、memtable、flush、compaction等路径中产生的标准内存分配请求。
kqmalloc通过线程本地缓存和多级无锁缓存降低小对象分配延迟及并发竞争，通过精细化的大小分级降低内存碎片，并通过透明大页、惰性释放和脏页回收降低TLB未命中和页面管理开销。

## 已验证环境

本文基于特定环境提供指导，在正式操作前请确保软硬件均满足要求。

**表1** 硬件要求

| 项目 | 规格 |
| ---- | ---- |
| CPU | 鲲鹏950处理器 |

**表2** kqmalloc二进制使用环境<a id="kqmalloc二进制使用环境"></a>

| 操作系统 | CPU类型 | 编译器 |
| -------- | ------- | ------ |
| openEuler 20.03 LTS SP1 | 鲲鹏920系列处理器 | GCC 7.3.0 / 毕昇4.2.0 |
| openEuler 22.03 LTS SP3 | 鲲鹏920系列处理器 | GCC 10.3.1 / 毕昇4.2.0 |
| openEuler 24.03 LTS SP3 | 鲲鹏950处理器 | GCC 12.3.1 / Clang 14.0.6 |

kqmalloc二进制运行环境要求glibc版本不低于2.34，详细安装要求请参见[kqmalloc安装指南](https://www.hikunpeng.com/document/detail/zh/kunpengaccel/system-lib/kqmalloc/docs/zh/kqmalloc/installation_guide.md)。

**表3** 操作系统和软件要求<a id="操作系统和软件要求"></a>

| 配置项 | 配置要求 | 获取地址 |
| ----------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| 操作系统 | openEuler 24.03 LTS SP3 | [获取链接](https://repo.huaweicloud.com/openeuler/openEuler-24.03-LTS-SP3/ISO/aarch64/openEuler-24.03-LTS-SP3-everything-aarch64-dvd.iso) |
| gcc版本 | gcc 12.3.1 | openEuler 24.03 LTS SP3版本自带 |
| Jdk版本 | 11 | 在openEuler 24.03 LTS SP3系统上，确保网络畅通情况下，利用Yum工具直接安装 |
| RocksDB版本 | 6.26.1 | [获取链接](https://github.com/facebook/rocksdb/tree/v6.26.1) |
| 优化特性补丁 | 0001-0005相关补丁 | [获取链接](https://gitcode.com/boostkit/rocksdb/tree/master/src/rocksdb-6.26.1/feature-patches) |
| kqmalloc二进制 | v0.22.0 | [获取地址](https://repo.boostkit.osinfra.cn/boostcore/kqmalloc/release/v0.22.0/) |

## 安装和使用特性

1. 使用git克隆RocksDB并切换到6.26.1版本，放在$HOME目录下。

   ```bash
   cd $HOME
   git clone https://github.com/facebook/rocksdb.git
   cd rocksdb/
   git checkout v6.26.1
   ```

2. 安装yum依赖和配置环境变量。

   ```bash
   yum install -y git make gcc-c++ snappy snappy-devel zlib zlib-devel bzip2 bzip2-devel lz4 lz4-devel zstd zstd-devel java java-devel java-11-openjdk-devel gflags gflags-devel flex python maven

   export JAVA_HOME=/usr/lib/jvm/java-11
   export PATH=$JAVA_HOME/bin:$PATH
   ```

3. （可选）获取优化特性的补丁文件，将其上传到$HOME目录下。

   获取路径请参见[表3操作系统和软件要求](#操作系统和软件要求)。

4. （可选）进入`$HOME/rocksdb`目录，按照feature-patches目录中的实际文件名依次应用0001-0005相关补丁。如果没有输出则说明合入成功。

5. 编译RocksDB的jar包和相关动态库以使能内存分配优化特性。

   1. 编译RocksDB的jar包和相关动态库。

      ```bash
      cd "$HOME/rocksdb"
      make clean
      PORTABLE=1 DEBUG_LEVEL=0 make rocksdbjava -j$nproc DISABLE_WARNING_AS_ERROR=1 DISABLE_JEMALLOC=1
      ```

   2. 替换本地Maven仓库中的jar包。

      ```bash
      cd "$HOME/rocksdb"
      cp java/target/rocksdbjni-6.26.1-linux64.jar \
         "~/.m2/repository/org/rocksdb/rocksdbjni/6.26.1/rocksdbjni-6.26.1.jar"
      cp java/target/rocksdbjni-6.26.1-linux64.jar.sha1 \
         "~/.m2/repository/org/rocksdb/rocksdbjni/6.26.1/rocksdbjni-6.26.1.jar.sha1"
      ```

6. 获取kqmalloc二进制内存库。

   根据当前操作系统、CPU类型和编译器，从[表3操作系统和软件要求](#操作系统和软件要求)中的获取地址下载`kqmalloc-v0.22.0.tar.gz`，并解压到`$HOME/kqmalloc`目录。kqmalloc二进制的使用环境请参见[kqmalloc二进制使用环境](#kqmalloc二进制使用环境)。

   ```bash
   cd "$HOME"
   wget https://repo.boostkit.osinfra.cn/boostcore/kqmalloc/release/v0.22.0/kqmalloc-v0.22.0.tar.gz
   mkdir -p kqmalloc
   tar -xzf kqmalloc-v0.22.0.tar.gz -C kqmalloc --strip-components=1
   ```

7. 使用`LD_PRELOAD`加载kqmalloc内存库并执行性能测试。

   ```bash
   export LD_PRELOAD="$HOME/kqmalloc/HIP12/lib/libkqmalloc.so"

   cd "$HOME/YCSB_RUN/YCSB_RUN/ycsb-rocksdb-binding-0.18.0-SNAPSHOT"
   taskset -c 0-15 ./bin/ycsb run rocksdb -s \
   -P workloads/workloada \
   -p fieldlength=256 -p fieldcount=1 \
   -p recordcount=100000000 -p operationcount=100000000 \
   -p rocksdb.dir="$HOME/data/workload_data/" \
   -p rocksdb.optionsfile="$HOME/data/configs/dbsnappyrun.ini" \
   -p rocksdb.cfs=default -p table=default -threads 5
   ```

   叠加使用GCC编译优化特性和内存分配优化特性后，YCSB测试工具workload a-f的性能平均提升10%，优化前后对比效果如[双特性叠加使能前后性能对比](#双特性叠加使能前后性能对比)所示。

   **图1** 双特性叠加使能前后性能对比<a id="双特性叠加使能前后性能对比"></a>

   <img src="figures/五特性叠加使能前后性能对比.png" alt="双特性叠加使能前后性能对比" style="zoom:40%;" />

## 安全检查与加固

ASLR（Address Space Layout Randomization，地址空间布局随机化）是一种针对缓冲区溢出的安全保护技术，通过对堆、栈、共享库映射等线性区布局的随机化，增加攻击者预测目的地址的难度，防止攻击者直接定位攻击代码位置，达到阻止溢出攻击的目的。

```bash
echo 2 > /proc/sys/kernel/randomize_va_space
cat /proc/sys/kernel/randomize_va_space
```

## 修订记录

| 发布日期 | 修订记录 |
| -------- | -------- |
| 2026-09-30 | 第一次正式发布。 |
