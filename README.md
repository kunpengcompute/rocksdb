# BoostKit RocksDB

## 项目品牌名称

RocksDB

### 最新消息

* [2026.03.30] 发布 `RocksDB CRC32 及 Filter 优化` V26.0.RC1 版本，通过引入 CRC32、pmull 硬件指令和 sve2 向量指令加速检验效率，优化布隆过滤器构建方法，高并发场景下性能提升 5% 以上。
* [2026.03.30] 发布 `RocksDB 适配 64K 页优化` 特性，通过编译 64K 大页内核减少 TLB 失效率，添加 jemalloc 在不同系统页下的判断，性能提升 5% 以上。

### 项目介绍

BoostKit RocksDB 是面向鲲鹏平台的 RocksDB 数据库优化补丁仓库，提供：

- **CRC32 及 Filter 优化补丁**：使用 CRC32、pmull 硬件指令和 SVE2 向量指令优化校验效率，改进布隆过滤器算法减少无效 IO。
- **64K 页适配优化补丁**：通过 64K 内核页大小减少 TLB 缓存未命中，优化内存对齐策略提升内存访问效率。

所有优化特性以补丁文件（patch）形式提供，需要对开源 RocksDB 源码进行编译集成。

仓库文档导航如下：

| 文档名称 | 内容说明 | 链接 |
| --- | --- | --- |
| rocksdb_crc32_optimization_feature_guide | CRC32优化原理、安装配置方法 | [特性指南](docs/zh/rocksdb_crc32_optimization_feature_guide.md) |
| rocksdb_filter_optimization_feature_guide | Filter 优化原理、安装配置方法 | [特性指南](docs/zh/rocksdb_filter_optimization_feature_guide.md) |
| 64kb_page_based_rocksdb_optimization_feature_guide | 64K 页适配优化原理、安装使用方法 | [特性指南](docs/zh/64kb_page_based_rocksdb_optimization_feature_guide.md) |

### 目录结构

```text
rocksdb-patch/
├── README.md                                                             # 仓库总览入口，说明分支与特性导航
├── docs/zh/
│   ├── rocksdb__release_notes.md            
#  版本发布说明
│   ├── rocksdb_crc32_optimization_feature_guide.md            # CRC32优化原理与使能指导
│   ├── rocksdb_filter_optimization_feature_guide.md            # Filter优化原理与使能指导
│   ├── 64kb_page_based_rocksdb_optimization_feature_guide.md             # 64K 页适配优化原理与使能指导
│   ├── figures/                                                          # 文档配图目录
│   │   ├── zh-cn_image_0000002516993780.png                              # CRC32 校验性能瓶颈图
│   │   ├── 优化特性使能前后性能对比.png                                    # CRC32 及 Filter 优化性能对比图
│   │   └── 优化特性使能前后性能对比 -0.png                                 # 64K 页优化性能对比图
│   └── public_sys-resources/                                             # 文档图标资源
│       ├── icon-caution.gif                                              # 注意图标
│       ├── icon-danger.gif                                               # 危险图标
│       ├── icon-note.gif                                                 # 说明图标
│       ├── icon-notice.gif                                               # 通知图标
│       ├── icon-tip.gif                                                  # 提示图标
│       └── icon-warning.gif                                              # 警告图标
├── 0001-crc32c-sve2-arm64-combined.patch                                 # CRC32 优化补丁（SVE2+PMULL）
├── 0002-filter_opt_6_1_2_final.patch                                     # Filter 优化补丁
└── 0001-64k-jemalloc-check.patch                                         # 64K 页适配优化补丁
```

### 特性简介

<table>
<thead>
<tr>
<th>分类</th>
<th>特性名称</th>
<th>特性文档</th>
<th>特性介绍</th>
</tr>
</thead>
<tbody>
<tr>
<td rowspan="2">校验加速</td>
<td>CRC32 硬件指令优化</td>
<td><a href="docs/zh/rocksdb_crc32_optimization_feature_guide.md">rocksdb_crc32_optimization_feature_guide.md</a></td>
<td>使用 CRC32、pmull 硬件指令和 SVE2 向量指令优化 CRC32 校验计算，消除 CPU 性能瓶颈，提升 I/O 吞吐。</td>
</tr>
<tr>
<td>智能布隆过滤器</td>
<td><a href="docs/zh/rocksdb_filter_optimization_feature_guide.md">rocksdb_filter_optimization_feature_guide.md</a></td>
<td>针对热数据场景动态增加布隆过滤器位图大小，提升判断精度减少误判率，降低无效磁盘 I/O。</td>
</tr>
<tr>
<td>内存页优化</td>
<td>64K 页适配优化</td>
<td><a href="docs/zh/64kb_page_based_rocksdb_optimization_feature_guide.md">64kb_page_based_rocksdb_optimization_feature_guide.md</a></td>
<td>通过 64K 内核页大小减少 TLB 缓存未命中和页表层级，优化内存对齐策略提升内存访问效率，QPS 提升 5% 以上。</td>
</tr>
</tbody>
</table>

### RocksDB 兼容性信息

| 特性版本 | 上游版本 | CPU | 操作系统 | GCC/工具链 |
| --- | --- | --- | --- | --- |
| RocksDB CRC32 及 Filter 优化 26.0.RC1 | RocksDB 6.1.2 | 鲲鹏 920 新型号处理器、鲲鹏 950 处理器 | openEuler 22.03 LTS SP4、openEuler 24.03 LTS SP3 | GCC 10.3.1 |
| RocksDB 适配 64K 页优化 26.0.RC1 | RocksDB 6.1.2 | 鲲鹏 920 新型号处理器、鲲鹏 950 处理器 | openEuler 22.03 LTS SP4、openEuler 24.03 LTS SP3 | GCC 10.3.1 |

### 工具限制与注意事项

- 优化特性以补丁文件（patch）形式提供，需要从源码编译集成，不支持直接 RPM 安装。
- CRC32 及 Filter 优化需要 CPU 支持 CRC32 硬件指令，可通过 `lscpu | grep Flags | grep crc32` 检查。
- 64K 页优化需要重新编译 64K 页大小的内核并重启选择新内核，可通过 `getconf PAGESIZE` 验证（回显 65536 表示已启用）。
- 编译 CRC32 优化时需要添加编译选项 `-march=armv8-a+crc`。
- 编译 RocksDB 时需要修改 BlockBasedTableConfig.java 文件第 38 行，将 true 改为 false。
- 编译选项中需指定 `DISABLE_JEMALLOC=1`，patch 中的判断用于控制 C++ 动态库与静态库的编译行为。
- 建议预先开启 ASLR 安全保护：`echo 2 >/proc/sys/kernel/randomize_va_space`。
- 需要安装 Java 1.8.0 及相关依赖包（snappy、zlib、lz4、zstd 等）。

### 特性版本维护策略

| 特性名称 | 当前版本 | 维护状态 | 说明 |
| --- | --- | --- | --- |
| RocksDB CRC32 及 Filter 优化 | 26.0.RC1 | 持续维护 | 提供 CRC32 硬件指令 + 智能布隆过滤器优化补丁 |
| RocksDB 适配 64K 页优化 | 26.0.RC1 | 持续维护 | 提供 jemalloc 兼容性判断补丁 |

### 版本维护策略

| 版本 | 维护策略 | 当前状态 | 后续状态 | EOL 日期 |
| --- | --- | --- | --- | --- |
| RocksDB 6.1.2 | 常规版本 | 维护 | - | - |

### 性能提升效果

| 特性名称 | 测试场景 | 数据集 | 规格 | QPS 提升 |
| --- | --- | --- | --- | --- |
| RocksDB CRC32 及 Filter 优化 | YCSB workloada、workloadc | 标准测试集 | 16U | 平均提升 5% |
| RocksDB 适配 64K 页优化 | YCSB workloada、workloadc | 标准测试集 | 16U | 平均提升 5% |

### 贡献声明

欢迎大家为社区做贡献。如果使用过程中有任何问题、建议、特性需求或 bug 报告，请提交：

- [Issues](https://gitcode.com/boostkit/rocksdb/issues)

贡献流程可参考：

- [BoostKit 社区贡献指南](https://gitcode.com/boostkit/community/blob/master/docs/contributor/contributing.md)

也欢迎在讨论区交流：

- [BoostKit Discussions](https://gitcode.com/boostkit/community/discussions)

### License

本项目的文档适用CC-BY 4.0许可证，具体请参见[LICENSE](https://gitcode.com/boostkit/rocksdb/tree/rocksdb-v6.1.2-patch/docs/LICENSE)文件。
