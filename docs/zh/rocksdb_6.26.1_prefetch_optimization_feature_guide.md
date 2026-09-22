# RocksDB 6.26.1 Memtable跳表、SST Block预取优化 特性指南

## 特性描述

### 简介

本文主要介绍RocksDB 6.26.1数据库预取优化特性的优化原理和安装使用方法。

RocksDB是Meta开发的基于C++和LSM-Tree的高性能嵌入式持久化键值存储引擎，广泛运用于数据库、缓存系统及实时数据处理等场景。

在RocksDB的MemTable跳表和SST Block查找中，指针追逐、restart offset读取及Key解码都可能产生缓存未命中，使CPU等待内存返回。原有实现只在部分路径提前读取下一次可能访问的数据，无法覆盖降层、顺序扫描和二分分支的后续访问。本优化根据查找层级和分支，在比较当前Key的同时提前读取下一层节点、同层后继以及左右子区间中点，尽量隐藏内存访问延迟并提升读密集场景吞吐。

### 原理描述

本特性通过在数据真正使用前发出缓存预取指令，将内存访问与Key比较、restart二分等计算阶段重叠，降低缓存未命中带来的停顿。

**跳表指针追逐优化**

访问当前节点后同时预取`x->Next(level - 1)`和`next->Next(level)`。前者为比较失败后的降层准备低层首节点，后者为同层继续前进准备下下个节点；当前轮Key比较期间，内存子系统可以并行搬运这些地址。

**Block查找预取优化**

在Block二分查找开始时预取初始中点；在顺序扫描时预取下一条Key；在每轮比较时同时计算并预取左右子区间中点。无论下一轮向左还是向右，候选restart offset都有机会提前进入缓存，从而减少分支方向造成的额外Miss。

预取适用于随机`Get`、`Seek`、范围查询起点定位以及MemTable未命中缓存的场景。

## 环境要求

本文基于特定环境提供指导，在正式操作前请确保软硬件均满足要求。

**表1**硬件要求

| 项目 | 说明                                                |
| ---- | --------------------------------------------------- |
| CPU  | 鲲鹏950处理器 |

**表2**操作系统和软件要求<a id="操作系统和软件要求"></a>

| 项目      | 版本                                                     | 下载链接                                                     |
| ----------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| 操作系统    | openEuler24.03 LTS SP3                                       | [获取链接](https://repo.huaweicloud.com/openeuler/openEuler-24.03-LTS-SP3/ISO/aarch64/openEuler-24.03-LTS-SP3-everything-aarch64-dvd.iso) |
| RocksDB | 6.26.1                                                       | [获取链接](https://github.com/facebook/rocksdb/tree/v6.26.1) |
| GCC     | 12.3.1                                                   | openEuler24.03 LTS SP3版本自带                               |
| Java     |  11                                                        | 在openEuler 24.03 LTS SP3系统上，确保网络畅通情况下，利用Yum工具直接安装 |
| patch文件   |          0001_prefetch_opt.patch                   | [获取链接](https://gitcode.com/boostkit/rocksdb/tree/master/src/rocksdb-6.26.1/feature-patches/0001_prefetch_opt.patch) |

## 安装环境

安装和使用该特性需先在RocksDB源码中应用该patch文件，再编译RocksDB。

1. 使用git克隆RocksDB并切换到6.26.1版本，放在主目录“\~”下。

   ```bash
   cd ~
   git clone https://github.com/facebook/rocksdb.git
   cd rocksdb/
   git checkout v6.26.1
   ```

2. 安装yum依赖和环境变量配置。

   ```bash
   yum install -y git make gcc-c++ snappy snappy-devel zlib zlib-devel bzip2 bzip2-devel lz4 lz4-devel zstd zstd-devel java java-devel java-11-openjdk-devel gflags gflags-devel flex python maven
   
   export JAVA_HOME=/usr/lib/jvm/java-11
   export PATH=$JAVA_HOME/bin:$PATH
   ```

3. 获取优化特性的补丁文件，将其上传到主目录“\~”下。

   获取路径请参见[**表2**操作系统和软件要求](#操作系统和软件要求)。

4. 执行以下命令，合入优化特性。如果没有输出则说明合入成功。

   ```bash
   cd ~/rocksdb
   git apply --whitespace=nowarn ~/0001_prefetch_opt.patch
   ```

5. 编译RocksDB的jar包和相关动态库，以使用优化特性。

   1. 编译RocksDB的jar包和相关动态库。
   
      ```bash
      make clean
      PORTABLE=1 DEBUG_LEVEL=0 make rocksdbjava -j`nproc` DISABLE_WARNING_AS_ERROR=1 DISABLE_JEMALLOC=1
      ```

   2. （可选）若是编译过程中报缺少jar包的错误，可以先清理文件，再手动下载缺少的jar包，然后重新进行编译。
   
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

   3. 替换本地Maven仓库中的jar包。
      
      ```bash
      cd ~/rocksdb
      cp java/target/rocksdbjni-6.26.1-linux64.jar \
         ~/.m2/repository/org/rocksdb/rocksdbjni/6.26.1/rocksdbjni-6.26.1.jar
      cp java/target/rocksdbjni-6.26.1-linux64.jar.sha1 \
         ~/.m2/repository/org/rocksdb/rocksdbjni/6.26.1/rocksdbjni-6.26.1.jar.sha1
      ```

   4. 提取原生动态库并设置`LD_LIBRARY_PATH`。
      
      ```bash
      # 创建库存放目录（供 YCSB 使用）
      mkdir -p ~/Test/rocksdb-lib
      # 清空旧文件
      rm -f ~/Test/rocksdb-lib/*
      # 解压.so文件
      unzip -jo ~/.m2/repository/org/rocksdb/rocksdbjni/6.26.1/rocksdbjni-6.26.1.jar "*.so" -d ~/Test/rocksdb-lib
      # 验证
      ls -lh ~/Test/rocksdb-lib/
      # 设置环境变量
      export LD_LIBRARY_PATH=~/Test/rocksdb-lib:$LD_LIBRARY_PATH
      ```

6. （可选）通过YCSB工具测试可以得到使能本特性前后的性能提升效果。

使用该预取优化特性，性能可平均提升约4%。

## 安全检查与加固

ASLR（Address Space Layout Randomization，地址空间布局随机化）是一种针对缓冲区溢出的安全保护技术，通过对堆、栈、共享库映射等线性区布局的随机化，增加攻击者预测目的地址的难度，防止攻击者直接定位攻击代码位置，达到阻止溢出攻击的目的。

```bash
echo 2 | sudo tee /proc/sys/kernel/randomize_va_space
cat /proc/sys/kernel/randomize_va_space
```

![](figures/zh-cn_image_0000002504021297.png)

## 修订记录

|文档版本| 发布日期   | 修改说明         |
|----------| ---------- | ---------------- |
|01| 2026-09-30 | 第一次正式发布。 |
