# 版本说明书

## 2026-09-30

### 修改记录

| 文档版本 | 发布日期   | 修改说明 |
| ---- | ---------- | -------- |
| 01   | 2026-09-30 | 首次发布RocksDB v6.26.1优化特性：MemTable跳表、SST Block预取优化；CRC32C标矢量混合优化；布隆过滤器SVE2向量化优化；动态SST层级容量优化；Index_block HashSearch优化；GCC编译优化与kqmalloc内存优化。 |

### 版本配套说明

#### 产品版本信息

| 产品名称 | 产品版本 |
| -------- | -------- |
| BoostDB | 26.2.RC1 |

#### 软件版本配套说明

|特性名称|软件类型|版本|
|--|--|--|
|RocksDB新增优化特性|OS|openEuler 24.03 LTS SP3|
|RocksDB新增优化特性|gcc版本|gcc 12.3.1|
|RocksDB新增优化特性|Jdk版本|1.8.0+|
|RocksDB新增优化特性|RocksDB|6.26.1|

#### 硬件版本配套说明

| 特性名称 | 硬件项目 | 要求说明 |
| ------------- | ------------- | ----------------------------------------- |
|RocksDB新增优化特性| 处理器 | 鲲鹏950处理器|

#### 病毒扫描结果

不涉及软件包发布，不涉及病毒扫描。

### 版本使用注意事项

无

### 版本说明

#### 更新说明

##### MemTable跳表、SST Block预取优化

在MemTable跳表和SST Block查找路径中增加分层、同层后继及二分分支感知的缓存预取，降低指针追逐、restart offset读取造成的缓存未命中。

##### CRC32C标矢量混合优化

使用SVE2、PMULL和crc32cx指令构建10路标量并行与8路矢量折叠混合流水，提升CRC32C校验在读写和压缩路径中的计算吞吐。运行时检测SVE2能力，不满足条件时回退到原有实现，保证校验结果和接口语义不变。

##### 布隆过滤器SVE2向量化优化

将多个哈希探测位置批量向量化计算，并行读取512位过滤器cache line中的目标word，通过位掩码完成探测，保持不产生假阴性的判定语义。SVE2不可用时自动使用标量路径，过滤器格式、哈希序列和返回语义保持兼容。

##### 动态SST层级容量优化

引入autumn_c层级缩放因子，根据当前使用的最高非空Level动态计算各层目标容量，以调节compaction频率、写放大和读放大。

##### Index_block HashSearch优化

优化前缀配置匹配、HashSearch元数据加载和ARM64 block解析，配置匹配时缩小候选Index Block/Data Block范围，配置不匹配时回退普通二分查找，减少无效比较和磁盘I/O。

##### GCC编译优化与kqmalloc内存优化

通过GCC PGO的“插桩构建、负载测试、反馈构建”流程围绕实际业务热点优化代码生成，并使用kqmalloc替换默认内存分配器，降低读写、缓存、memtable、flush和compaction路径的分配开销。

#### 已解决的问题

无。

#### 遗留问题

无

### 版本配套文档

|文档名称|内容简介|交付形式|
|--|--|--|
|[《RocksDB 6.26.1 MemTable跳表、SST Block预取优化 特性指南》](https://gitcode.com/boostkit/rocksdb/tree/master/docs/zh/rocksdb_6.26.1_prefetch_optimization_feature_guide.md)|提供预取优化的原理、环境要求、patch合入、编译和YCSB验证指导。|开源仓|
|[《RocksDB 6.26.1 CRC32C标矢量混合优化 特性指南》](https://gitcode.com/boostkit/rocksdb/tree/master/docs/zh/rocksdb_6.26.1_crc32c_optimization_feature_guide.md)|提供CRC32C SVE2/PMULL混合优化的原理、回退机制和使能指导。|开源仓|
|[《RocksDB 6.26.1 布隆过滤器SVE2向量化优化 特性指南》](https://gitcode.com/boostkit/rocksdb/tree/master/docs/zh/rocksdb_6.26.1_bloomfilter_optimization_feature_guide.md)|提供布隆过滤器向量化探测优化的原理、兼容性和测试指导。|开源仓|
|[《RocksDB 6.26.1 autumn_c动态Level容量优化 特性指南》](https://gitcode.com/boostkit/rocksdb/tree/master/docs/zh/rocksdb_6.26.1_dynamic_capacity_optimization_feature_guide.md)|提供`autumn_c`动态Level容量计算、配置和验证指导。|开源仓|
|[《RocksDB 6.26.1 Index_block Hashsearch优化 特性指南》](https://gitcode.com/boostkit/rocksdb/tree/master/docs/zh/rocksdb_6.26.1_hashsearch_optimization_feature_guide.md)|提供Index_block HashSearch的前缀匹配、元数据解析、回退逻辑和性能验证指导。|开源仓|
|[《RocksDB 6.26.1 GCC编译优化与kqmalloc内存优化 特性指南》](https://gitcode.com/boostkit/rocksdb/tree/master/docs/zh/rocksdb_6.26.1_gcc_kqmalloc_optimization_feature_guide.md)|提供GCC PGO、kqmalloc内存库切换、运行时配置和性能验证指导。|开源仓|

### 获取文档的方法

您可以通过访问[开源仓](https://gitcode.com/boostkit/rocksdb/tree/master/docs/zh)浏览和获取相关文档。

## 2026-06-30

### 修改记录

| 文档版本 | 发布日期   | 修改说明                                                                                                                                 |
| ---- | ---------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| 01   | 2026-06-30 |首次发布RocksDB proxy (Kvrocks) 网络多路径特性。 |

### 版本配套说明

#### 产品版本信息

| 产品名称      | 产品版本     |
| --------- | -------- |
| BoostDB | 26.1.RC1 |

#### 软件版本配套说明

|特性名称|软件类型|版本|
|--|--|--|
|RocksDB proxy (Kvrocks) 网络多路径|OS|openEuler 22.03 LTS SP4 for ARM、openEuler 24.03 LTS SP3 for ARM|
|RocksDB proxy (Kvrocks) 网络多路径|Kvrocks|2.2.0|

#### 硬件版本配套说明

| 特性名称          | 硬件项目          | 要求说明                                      |
| ------------- | ------------- | ----------------------------------------- |
| RocksDB proxy (Kvrocks) 网络多路径    | 处理器           | 鲲鹏920新型号处理器、鲲鹏950处理器         |
| RocksDB proxy (Kvrocks) 网络多路径    |网卡   | 25GE网卡*2      |

#### 病毒扫描结果

不涉及软件包发布，不涉及病毒扫描。

### 版本使用注意事项

无

### 版本说明

#### 更新说明

##### RocksDB proxy (Kvrocks) 网络多路径

新增RocksDB proxy (Kvrocks)网络多路径特性，通过识别特定业务进程的流量特征，将指定业务进程的网络流量优先由当前业务进程所在NUMA上的网卡队列进行接收，从而实现业务进程网络请求与网络中断的亲和性。

#### 已解决的问题

无

#### 遗留问题

无

### 版本配套文档

|文档名称|内容简介|交付形式|
|--|--|--|
|《RocksDB proxy (Kvrocks) 网络多路径 特性指南》|本文档提供RocksDB proxy (Kvrocks) 网络多路径特性的环境要求、特性使能指导。|开源仓|

### 获取文档的方法<a name="ZH-CN_TOPIC_0000002544372643"></a>

您可以通过访问[开源仓](https://gitcode.com/boostkit/rocksdb/tree/rocksdb-v6.1.2-patch/docs)浏览和获取相关文档。

## 2026-03-30

### 修改记录

| 文档版本 | 发布日期   | 修改说明                                                                                                                                 |
| ---- | ---------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| 01   | 2026-03-30 |- 首次发布RocksDB适配64K页优化特性。<br> - 首次发布RocksDB CRC32优化特性。<br> - 首次发布RocksDB Filter优化特性。 |

### 版本配套说明

#### 产品版本信息

| 产品名称      | 产品版本     |
| --------- | -------- |
| BoostDB | 26.0.RC1 |

#### 软件版本配套说明

|特性名称|软件类型|版本|
|--|--|--|
|RocksDB适配64K页优化、RocksDB CRC32优化、RocksDB Filter优化|OS|openEuler 22.03 LTS SP4、openEuler 24.03 LTS SP3|
|RocksDB适配64K页优化、RocksDB CRC32优化、RocksDB Filter优化|RocksDB|6.1.2|

#### 硬件版本配套说明

| 特性名称          | 硬件项目          | 要求说明                                      |
| ------------- | ------------- | ----------------------------------------- |
| RocksDB适配64K页优化、RocksDB CRC32优化、RocksDB Filter优化      | 处理器           | 鲲鹏920新型号处理器、鲲鹏950处理器器                  |

#### 病毒扫描结果

不涉及软件包发布，不涉及病毒扫描。

### 版本使用注意事项

无

### 版本说明

#### 更新说明

##### RocksDB适配64K页优化

为了提升RocksDB在鲲鹏服务器中的整体性能表现与系统稳定性，鲲鹏BoostKit数据库使能套件新增RocksDB适配64K页优化特性，该特性通过编译64K大页内核来有效减少TLB的失效率，同时添加了jemalloc在不同系统页下的判断。

##### RocksDB CRC32优化

新增RocksDB CRC32优化特性，通过引入CRC32、pmull硬件指令和sve2向量指令来加速检验效率，有效提升高并发下的系统性能。

##### RocksDB Filter优化

新增RocksDB Filter优化特性，通过优化布隆过滤器的构建方法，减少无效IO，提升RocksDB在鲲鹏服务器中的整体性能表现与系统稳定性。

#### 已解决的问题

无

#### 遗留问题

无

### 版本配套文档

|文档名称|内容简介|交付形式|
|--|--|--|
|《RocksDB适配64K页优化 特性指南》|本文档提供RocksDB适配64K页优化特性的环境要求、特性使能指导。|开源仓|
|《RocksDB CRC32优化 特性指南》|本文档提供RocksDB适配64K页优化特性的环境要求、特性使能指导。|开源仓|
|《RocksDB Filter优化 特性指南》|本文档提供RocksDB适配64K页优化特性的环境要求、特性使能指导。|开源仓|

### 获取文档的方法<a name="ZH-CN_TOPIC_0000002544372643"></a>

您可以通过访问[开源仓](https://gitcode.com/boostkit/rocksdb/tree/rocksdb-v6.1.2-patch/docs)浏览和获取相关文档。
