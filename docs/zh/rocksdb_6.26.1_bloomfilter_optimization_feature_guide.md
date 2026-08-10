# RocksDB 6.26.1 布隆过滤器SVE2向量化优化 特性指南

## 特性描述

### 简介

本文主要介绍RocksDB 6.26.1数据库布隆过滤器查询优化特性的优化原理和安装使用方法。

RocksDB是Meta开发的基于C++和LSM-Tree的高性能嵌入式持久化键值存储引擎，广泛运用于数据库、缓存系统及实时数据处理等场景。

RocksDB查询SST文件时，布隆过滤器先根据键的哈希值检查位数组，快速排除不可能存在的键，减少后续索引块（Index Block）和数据块（Data Block）访问。原有Arm处理器实现逐个计算和检查探测位置，探测数量较多时会增加循环和访存开销。本优化批量计算和检查多个探测位置，降低单次过滤查询的CPU开销。

### 原理描述

在布隆过滤器查询流程中，基础哈希计算已经生成待查询键的初始哈希值h，并确定用于派生后续哈希值的哈希种子c。其中，h表示当前查询键的基础哈希结果，c表示生成后续探测哈希值时使用的固定种子。

本特性利用SVE2的并行计算能力，将原本逐个生成、逐个检查的哈希探测位置改为批量处理，减少重复计算和数据访问。

生成探测位置时，优化实现预先计算c的0次幂至7次幂，并将h复制到8个32位向量通道（lane）中。每个通道分别使用一个预计算值生成对应的哈希结果，因此一批最多可以得到8个连续的探测位置，避免在循环中依次计算。

检查探测位置时，每个哈希结果用于定位512位缓存行（cache line）中的一个目标二进制位：高4位用于确定16个32位数据字（word）中的目标数据字，随后的5位用于确定该数据字内的具体位置（bit-in-word）。系统根据该位置生成32位掩码，并通过按位与运算检查目标位。任意一个目标位未设置时，可以判定待查询键不存在；所有目标位均已设置时，表示该键可能存在，需要继续执行后续查询。

向量化优化只改变探测位置的计算和检查方式，不改变布隆过滤器的存储格式、哈希结果和查询语义。在支持SVE2的平台上，RocksDB自动使用向量化实现；在不支持SVE2的平台上，RocksDB继续使用原有实现，保证兼容性。

## 环境要求

本文基于特定环境提供指导，在正式操作前请确保软硬件均满足要求。

**表1** 硬件要求

| 项目   | 说明          |
| ------ | ------------- |
| CPU    | 鲲鹏950处理器 |

**表2** 操作系统和软件要求<a id="操作系统和软件要求"></a>

| 项目                                            | 版本                         | 下载链接                                                                                                                          |
| ----------------------------------------------- | ---------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| 操作系统                                        | openEuler 24.03 LTS SP3      | [获取链接](https://repo.huaweicloud.com/openeuler/openEuler-24.03-LTS-SP3/ISO/aarch64/openEuler-24.03-LTS-SP3-everything-aarch64-dvd.iso) |
| GNU编译器套件（GNU Compiler Collection，GCC）版本 | GCC 12.3.1                   | openEuler 24.03 LTS SP3版本自带                                                                                                  |
| Java开发工具包（Java Development Kit，JDK）版本  | 1.8.0及以上                  | 在openEuler 24.03 LTS SP3系统网络畅通的情况下，使用Yum工具直接安装                                                               |
| RocksDB版本                                     | 6.26.1                       | [获取链接](https://github.com/facebook/rocksdb/tree/v6.26.1)                                                                      |
| 补丁文件                                        | 0003_bloomfilter_opt.patch   | [获取链接](https://gitcode.com/boostkit/rocksdb/tree/master/src/rocksdb-6.26.1/feature-patches/0003_bloomfilter_opt.patch)            |

## 安装环境

安装和使用该特性需先在RocksDB源码中应用该补丁文件，再编译RocksDB。

1. 使用Git克隆RocksDB并切换到6.26.1版本，放在主目录“\~”下。

   ```bash
   cd ~
   git clone https://github.com/facebook/rocksdb.git
   cd rocksdb/
   git checkout v6.26.1
   ```

2. 使用Yum安装依赖并配置环境变量。

   ```bash
   yum install -y git make gcc-c++ snappy snappy-devel zlib zlib-devel bzip2 bzip2-devel lz4 lz4-devel zstd zstd-devel java java-devel java-11-openjdk-devel gflags gflags-devel flex python maven
   
   export JAVA_HOME=/usr/lib/jvm/java-1.8.0
   export PATH=$JAVA_HOME/bin:$PATH
   ```

3. 获取优化特性的补丁文件，将其上传到主目录“\~”下。

   获取路径请参见[**表2** 操作系统和软件要求](#操作系统和软件要求)。

4. 执行以下命令，合入优化特性。如果没有输出则说明合入成功。

   ```bash
   cd ~/rocksdb
   patch -p1 < ~/0003_bloomfilter_opt.patch
   ```

5. 编译RocksDB的Java归档（Java Archive，JAR）包和相关动态库，以使用优化特性。

   1. 修复原生代码在编译JAR包和相关动态库时的问题。

      1. 进入修改原生代码路径。

         ```bash
         cd ~/rocksdb
         ```

      2. 打开BlockBasedTableConfig.java文件。

         ```bash
         vim java/src/main/java/org/rocksdb/BlockBasedTableConfig.java
         ```

      3. 按“i”进入编辑模式，修改第38行，将true改为false。(若为false则忽略)

         ```txt
         # 修改第38行，true改为false
         verifyCompression = false;
         ```

      4. 按“Esc”键，输入 **:wq!**，按“Enter”保存并退出编辑。

   2. 编译RocksDB的JAR包和相关动态库。

      ```bash
      make clean
      PORTABLE=1 DEBUG_LEVEL=0 make rocksdbjava -j`nproc` DISABLE_WARNING_AS_ERROR=1 DISABLE_JEMALLOC=1
      ```

6. （可选）通过YCSB工具测试可以得到使能本特性前后的性能提升效果。

## 安全检查与加固

地址空间布局随机化（Address Space Layout Randomization，ASLR）是一种针对缓冲区溢出的安全保护技术，通过对堆、栈、共享库映射等线性区布局的随机化，增加攻击者预测目的地址的难度，防止攻击者直接定位攻击代码位置，达到阻止溢出攻击的目的。

```bash
echo 2 | sudo tee /proc/sys/kernel/randomize_va_space
cat /proc/sys/kernel/randomize_va_space
```

## 修订记录

| 发布日期   | 修订记录         |
| ---------- | ---------------- |
| 2026-09-30 | 第一次正式发布。 |
