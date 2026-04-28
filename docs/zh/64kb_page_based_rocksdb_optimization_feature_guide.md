# RocksDB适配64K页优化 特性指南

## 特性描述<a name="ZH-CN_TOPIC_0000002512120258"></a>

### 简介<a name="ZH-CN_TOPIC_0000002543640185"></a>

本文主要介绍RocksDB适配64K页优化特性的优化原理和安装使用方法。

RocksDB是由Meta（原Facebook）开发的一款高性能、嵌入式、持久化键值存储引擎，基于C++实现，支持嵌入式使用，也可作为客户端-服务器（C/S）模式下的存储数据库。RocksDB采用Log-Structured Merge-Tree（LSM-Tree）数据结构，通过将随机写入转化为顺序写入，显著提升写入吞吐量，尤其适用于高并发写入场景。同时，RocksDB在点查询与范围查询方面也表现出色，广泛应用于数据库、缓存系统及实时数据处理等场景。

在原始4K页面大小的系统配置下，RocksDB在高并发写入场景中容易出现较高的TLB（Translation Lookaside Buffer）缓存未命中（TLB Cache Miss）指标。而采用64K内核可有效减少页表层级与数量，显著降低ITLB（Instruction TLB）未命中率及减少缺页异常频率，从而提升吞吐性能。

### 原理描述<a name="ZH-CN_TOPIC_0000002543720175"></a>

RocksDB适配64K页优化特性通过减少TLB缺失，大幅提升内存访问效率。

TLB是CPU内存管理单元（MMU）中的一个关键硬件缓存，用于存储最近使用过的虚拟页号到物理页帧号的映射关系。程序运行时，指令中引用的内存地址通常是虚拟地址，而CPU在访问实际内存（RAM）时，必须通过MMU将这些虚拟地址转换为物理地址。TLB的作用类似于页表的高速缓存，当所需映射关系存在于TLB中时，CPU无需遍历整个页表，从而显著减少地址转换的开销。

在Linux内核采用64KB内存页管理机制的环境下，RocksDB通过优化内存对齐策略，显著减少了TLB缺失（TLB Miss），从而提升了内存访问效率。具体而言，RocksDB将读写操作中使用的Block（数据块）与内存页边界对齐，避免了跨页访问带来的性能损耗。这种对齐方式也有助于优化Block Cache的管理效率，进一步提高数据库的读写性能。

此外，在编译RocksDB时，如果启用了jemalloc内存分配器，还需确保当前环境中的jemalloc库版本与64KB页大小的内核兼容。为此，建议在构建过程中增加对jemalloc兼容性的判断逻辑，以避免因版本不匹配而导致的潜在运行问题。优化patch就是进行了这个判断。

查看当前Page Size大小：

```
getconf PAGESIZE
```

回显4096表示当前系统为4K页，需要重新编译内核；回显65536表示当前系统为64K页，说明已经使能该优化特性。


## 已验证环境<a name="ZH-CN_TOPIC_0000002512280240"></a>

本文基于特定环境提供指导，在正式操作前请确保软硬件均满足要求。

**表 1** 硬件要求<a id="硬件要求"></a>

|项目|规格|
|--|--|
|CPU|鲲鹏920新型号处理器、鲲鹏950处理器|


**表 2** 操作系统和软件要求<a id="操作系统和软件要求"></a>

|项目|版本|获取地址|
|--|--|--|
|操作系统|openEuler 22.03 LTS SP4、openEuler 24.03 LTS SP3|openEuler 22.03 LTS SP4：[获取链接](https://repo.huaweicloud.com/openeuler/openEuler-22.03-LTS-SP4/ISO/aarch64/openEuler-22.03-LTS-SP4-everything-aarch64-dvd.iso)<br>openEuler 24.03 LTS SP3：[获取链接](https://repo.huaweicloud.com/openeuler/openEuler-24.03-LTS-SP3/ISO/aarch64/openEuler-24.03-LTS-SP3-everything-aarch64-dvd.iso)|
|RocksDB|6.1.2|[获取链接](https://github.com/facebook/rocksdb/tree/v6.1.2)|
|GCC|10.3.1|openEuler 22.03 LTS SP4版本自带|
|Java|1.8.0|在openEuler 22.03 LTS SP4系统上，确保网络畅通情况下，利用Yum工具直接安装|
|patch文件|0001-64k-jemalloc-check.patch|[获取链接](https://gitcode.com/boostkit/rocksdb/blob/rocksdb-v6.1.2-patch/0001-64k-jemalloc-check.patch)|


## 安装和使用特性<a name="ZH-CN_TOPIC_0000002512120260"></a>

RocksDB适配64K页优化特性针对RocksDB 6.1.2版本开发，以编译内核+patch文件形式提供。安装和使用该特性，需先重新编译64K页的内核，重启之后选择编译后的64K页内核，再导入patch文件，最后进行RocksDB的编译。

1. 调整openEuler操作系统内核的Page Size为64KB，并重启选择64K页的内核。详细操作请参见《MySQL 调优指南》的[调整内核Page Size为64KB](https://www.hikunpeng.com/document/detail/zh/kunpengdbs/ecosystemEnable/MySQL/kunpengdbstune_05_0012.html)。
2. 使用git克隆RocksDB并切换到6.1.2版本，放在主目录“\~”下。

    ```
    cd ~
    git clone https://github.com/facebook/rocksdb.git
    cd rocksdb/
    git checkout v6.1.2
    ```

3. 安装yum依赖和环境变量配置。

    ```
    yum install -y git make gcc-c++ snappy snappy-devel zlib zlib-devel bzip2 bzip2-devel lz4 lz4-devel zstd zstd-devel java java-devel java-11-openjdk-devel gflags gflags-devel flex python maven
    
    export JAVA_HOME=/usr/lib/jvm/java-1.8.0
    export PATH=$JAVA_HOME/bin:$PATH
    ```

4. 获取优化特性的补丁文件，将其上传到主目录“\~”下。获取路径请参见[**表 2** 操作系统和软件要求](#操作系统和软件要求)。
5. 执行以下命令，合入优化特性。没有输出则说明合入成功。

    ```
    cd ~/rocksdb
    git apply --whitespace=nowarn < ~/0001-64k-jemalloc-check.patch
    ```

6. 编译RocksDB的jar包和相关动态库，以使用优化特性。
    1. 修改RocksDB源代码在编译jar包和相关动态库时的bug。
        1. 打开文件。

            ```
            cd ~/rocksdb
            vim java/src/main/java/org/rocksdb/BlockBasedTableConfig.java
            ```

        2. 按“i”进入编辑模式，修改第38行，将true改为false。

            ```
            # 修改第 38 行，true 改为 false
            verifyCompression = false;
            ```

        3. 按“Esc”键，输入 **:wq!**，按“Enter”保存并退出编辑。

    2. 编译RocksDB的jar包和相关动态库。

        ```
        PORTABLE=1 DEBUG_LEVEL=0 make rocksdbjava -j`nproc` DISABLE_WARNING_AS_ERROR=1 DISABLE_JEMALLOC=1
        ```

        >![](public_sys-resources/icon-note.gif) **说明：** 
        >由于RocksDB在启用jemalloc后编译生成的jar包在直接使用时必然报错，因此编译选项中明确指定了DISABLE\_JEMALLOC。patch中的相关判断主要用于控制C++动态库与静态库的编译行为。

    3. （可选）若是编译过程中出现缺少jar包的错误，可以先清理文件，再手动下载缺少的jar包，然后重新进行编译。

        ```
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

7. （可选）通过YCSB工具测试可以得到使能本特性前后的性能提升效果，详细测试步骤请参见《[YCSB测试指导](https://www.hikunpeng.com/document/detail/zh/kunpengdbs/testguide/tstg/kunpengycsbformong_11_0001.html)》。RocksDB适配64K页优化可以使16U规格下两个用例workloada和workloadc的性能平均提升5%，优化前后对比效果如[**图 1** 优化特性使能前后性能对比](#优化特性使能前后性能对比)所示。

    **图 1** 优化特性使能前后性能对比<a name="fig144438251669"></a><a id="优化特性使能前后性能对比"></a><br>
    ![](figures/优化特性使能前后性能对比-0.png "优化特性使能前后性能对比-0")

## 安全检查与加固<a name="ZH-CN_TOPIC_0000002549203369"></a>

ASLR（Address Space Layout Randomization，地址空间布局随机化）是一种针对缓冲区溢出的安全保护技术，通过对堆、栈、共享库映射等线性区布局的随机化，增加攻击者预测目的地址的难度，防止攻击者直接定位攻击代码位置，达到阻止溢出攻击的目的。

```
echo 2 >/proc/sys/kernel/randomize_va_space
```

![](figures/zh-cn_image_0000002504021297.png)


## 修订记录<a name="ZH-CN_TOPIC_0000002543640187"></a>

|发布日期|修订记录|
|--|--|
|2026-03-30|第一次正式发布。|



