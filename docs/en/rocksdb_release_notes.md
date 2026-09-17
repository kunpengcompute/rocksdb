# Release Notes

<!-- md-trans-meta sourceCommit=cef139c82914af4e0f704edede350a618687b4e3 translatedAt=2026-09-15T06:52:42.345Z pushedAt=2026-09-15T08:18:42.291Z -->

## 2026-09-30

### Change History

| Version | Date | Description |
| ---- | ---------- | -------- |
| 01   | 2026-09-30 | Released RocksDB v6.26.1 optimization features: MemTable skip list and SST block prefetch optimization; CRC32C scalar-vector hybrid optimization; Bloom filter SVE2 vectorization-based optimization; dynamic SST level capacity optimization; index block HashSearch optimization; GCC compilation optimization; and KQMalloc memory allocation optimization. |

### Version Mapping

#### Product Version Information

| Product Name | Product Version |
| -------- | -------- |
| BoostDB | 26.2.RC1 |

#### Software Version Mapping

| Feature | Software Type | Version |
|--|--|--|
| New RocksDB optimization features | OS | openEuler 24.03 LTS SP3 |
| New RocksDB optimization features | GCC | 12.3.1 |
| New RocksDB optimization features | JDK | 1.8.0+ |
| New RocksDB optimization features | RocksDB | 6.26.1 |

#### Hardware Version Mapping

| Feature | Hardware Item | Requirement |
| ------------- | ------------- | ----------------------------------------- |
| New RocksDB optimization features | Processor | Kunpeng 950 |

#### Virus Scan Results

Virus scanning is not involved because no software package is released.

### Important Notes

None

### Release Notes

#### Change Description

##### MemTable Skip List and SST Block Prefetch Optimization

This feature introduces level-aware, same-level-successor-aware, and binary-search-branch-aware cache prefetch to the MemTable skip list and SST block lookup paths, reducing cache misses caused by pointer chasing and restart-offset reads.

##### CRC32C Scalar-Vector Hybrid Optimization

This feature leverages SVE2, pmull, and crc32cx instructions to build a hybrid pipeline combining 10-way scalar parallelism with 8-way vector folding, improving CRC32C checksum computation throughput in the read, write, and compression paths. It detects SVE2 support at runtime and falls back to the original implementation when SVE2 is unavailable, while preserving checksum results and interface semantics.

##### Bloom Filter SVE2 Vectorization-based Optimization

This feature batch-vectorizes multiple hash probe positions, parallel-reads the target words from a 512-bit filter cache line, and performs the probes via bitmasks, preserving no-false-negative decision semantics. It automatically falls back to a scalar path when SVE2 is unavailable, maintaining compatibility with the filter format, hash sequence, and return semantics.

##### Dynamic SST Level Capacity Optimization

This feature introduces an `autumn_c` level-scaling factor that dynamically computes the target capacity of each level based on the highest non-empty level currently in use, thereby tuning compaction frequency, write amplification, and read amplification.

##### Index Block HashSearch Optimization

This feature optimizes prefix configuration matching, HashSearch metadata loading, and AArch64 block parsing. When the prefix configuration matches, it narrows the range of candidate index/data blocks; when it does not match, it falls back to regular binary search, reducing unnecessary comparisons and drive I/O.

##### GCC Compilation Optimization and KQMalloc Memory Allocation Optimization

This feature uses the GCC PGO workflow—instrumented build, workload testing, and feedback-based build—to optimize code generation around the actual workload hotspots, and replaces the default memory allocator with KQMalloc to reduce allocation overhead in reads/writes, caching, MemTable access, flushing, and compaction.

#### Resolved Issues

None

#### Known Issues

None

### Related Documentation

| Document | Description | Delivery Method |
|--|--|--|
| [RocksDB 6.26.1 MemTable Skip List and SST Block Prefetch Optimization Feature Guide](https://gitcode.com/boostkit/rocksdb/tree/master/docs/en/rocksdb_6.26.1_prefetch_optimization_feature_guide.md) | Provides the principles, environment requirements, patch integration, compilation, and YCSB verification guidance for the prefetch optimization. | Open-source repository |
| [RocksDB 6.26.1 CRC32C Scalar-Vector Hybrid Optimization Feature Guide](https://gitcode.com/boostkit/rocksdb/tree/master/docs/en/rocksdb_6.26.1_crc32c_optimization_feature_guide.md) | Provides the principles, fallback mechanism, and enablement guidance for CRC32C SVE2/pmull hybrid optimization. | Open-source repository |
| [RocksDB 6.26.1 Bloom Filter SVE2 Vectorization-based Optimization Feature Guide](https://gitcode.com/boostkit/rocksdb/tree/master/docs/en/rocksdb_6.26.1_bloomfilter_optimization_feature_guide.md) | Provides the principles, compatibility, and testing guidance for Bloom filter vectorized probing optimization. | Open-source repository |
| [RocksDB 6.26.1 autumn_c Dynamic Level Capacity Optimization Feature Guide](https://gitcode.com/boostkit/rocksdb/tree/master/docs/en/rocksdb_6.26.1_dynamic_capacity_optimization_feature_guide.md) | Provides the `autumn_c` dynamic level capacity calculation, configuration, and verification guidance. | Open-source repository |
| [RocksDB 6.26.1 Index Block HashSearch Optimization Feature Guide](https://gitcode.com/boostkit/rocksdb/tree/master/docs/en/rocksdb_6.26.1_hashsearch_optimization_feature_guide.md) | Provides the prefix matching, metadata parsing, fallback logic, and performance verification guidance for index block HashSearch optimization. | Open-source repository |
| [RocksDB 6.26.1 GCC Compilation Optimization and KQMalloc Memory Allocation Optimization Feature Guide](https://gitcode.com/boostkit/rocksdb/tree/master/docs/en/rocksdb_6.26.1_gcc_kqmalloc_optimization_feature_guide.md) | Provides the GCC PGO, KQMalloc memory library switching, runtime configuration, and performance verification guidance. | Open-source repository |

### Obtaining Documentation

Visit the [open-source repository](https://gitcode.com/boostkit/rocksdb/tree/master/docs/en) to view or download required documents.

## 2026-06-30

### Change History

| Version| Date  | Description                                                                                                                                |
| ---- | ---------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| 01   | 2026-06-30 |Released the RocksDB proxy (Kvrocks) network multipathing feature.|

### Version Mapping

#### Product Version Information

| Product Name     | Version    |
| --------- | -------- |
| BoostDB | 26.1.RC1 |

#### Software Version Mapping

|Feature|Software|Version|
|--|--|--|
|RocksDB proxy (Kvrocks) network multipathing|OS|openEuler 22.03 LTS SP4 for Arm or openEuler 24.03 LTS SP3 for Arm|
|RocksDB proxy (Kvrocks) network multipathing|Kvrocks|2.2.0|

#### Hardware Version Mapping

| Feature         | Item         | Requirement                                     |
| ------------- | ------------- | ----------------------------------------- |
| RocksDB proxy (Kvrocks) network multipathing   | Processor          | New Kunpeng 920 processor model or Kunpeng 950 processor        |
| RocksDB proxy (Kvrocks) network multipathing   |NIC  | 2 × 25GE NIC     |

#### Virus Scan Results

Virus scanning is not involved because no software package is released.

### Important Notes

None

### Release Notes

#### Change Description

##### RocksDB Proxy (Kvrocks) Network Multipathing

The RocksDB proxy (Kvrocks) network multipathing feature is added. By analyzing traffic patterns of specific service processes, this feature ensures that network traffic of each process is preferentially handled by NIC queues on its local NUMA node, thereby establishing affinity between service processes and their network interrupts.

#### Resolved Issues

None

#### Known Issues

None

### Related Documentation

|Document|Description|Delivery Method|
|--|--|--|
|*RocksDB Proxy (Kvrocks) Network Multipathing Feature Guide*|Describes the environment requirements and provides guidance on enabling the RocksDB proxy (Kvrocks) network multipathing feature.|Open-source repository|

### Obtaining Documentation<a name="EN-US_TOPIC_0000002544372643"></a>

Visit the [open-source repository](https://gitcode.com/boostkit/rocksdb/tree/rocksdb-v6.1.2-patch/docs) to view or download required documents.

## 2026-03-30

### Change History

| Version| Date  | Description                                                                                                                                |
| ---- | ---------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| 01   | 2026-03-30 |- Released the 64 KB page-based RocksDB optimization feature.<br> - Released the RocksDB CRC32 optimization feature.<br> - Released the RocksDB filter optimization feature.|

### Version Mapping

#### Product Version Information

| Product Name     | Version    |
| --------- | -------- |
| BoostDB | 26.0.RC1 |

#### Software Version Mapping

|Feature|Software|Version|
|--|--|--|
|64 KB page-based RocksDB optimization, RocksDB CRC32 optimization, and RocksDB filter optimization|OS|openEuler 22.03 LTS SP4 or openEuler 24.03 LTS SP3|
|64 KB page-based RocksDB optimization, RocksDB CRC32 optimization, and RocksDB filter optimization|RocksDB|6.1.2|

#### Hardware Version Mapping

| Feature         | Item         | Requirement                                     |
| ------------- | ------------- | ----------------------------------------- |
| 64 KB page-based RocksDB optimization, RocksDB CRC32 optimization, and RocksDB filter optimization     | Processor          | New Kunpeng 920 processor model or Kunpeng 950 processor                 |

#### Virus Scan Results

Virus scanning is not involved because no software package is released.

### Important Notes

None

### Release Notes

#### Change Description

##### 64 KB Page-based RocksDB Optimization

To improve the overall performance and system stability of RocksDB on Kunpeng servers, the 64 KB page-based RocksDB optimization feature is added to Kunpeng BoostKit for Database. This feature compiles the 64 KB page kernel to effectively reduce the TLB miss rate, and supports system page size checks when jemalloc is used.

##### RocksDB CRC32 Optimization

The RocksDB CRC32 optimization feature is added. This feature uses CRC32, pmull hardware instructions, and SVE2 vector instructions to accelerate the verification efficiency and improve the system performance in high concurrency scenarios.

##### RocksDB Filter Optimization

The RocksDB filter optimization feature is added. This feature optimizes the construction of the intelligent Bloom filter to reduce invalid I/O, improving the overall performance and system stability of RocksDB on Kunpeng servers.

#### Resolved Issues

None

#### Known Issues

None

### Related Documentation

|Document|Description|Delivery Method|
|--|--|--|
|*64 KB Page-based RocksDB Optimization Feature Guide*|Describes the environment requirements and provides guidance on enabling the 64 KB page-based RocksDB optimization feature.|Open-source repository|
|*RocksDB CRC32 Optimization Feature Guide*|Describes the environment requirements and provides guidance on enabling the RocksDB CRC32 optimization feature.|Open-source repository|
|*RocksDB Filter Optimization Feature Guide*|Describes the environment requirements and provides guidance on enabling the RocksDB filter optimization feature.|Open-source repository|

### Obtaining Documentation<a name="EN-US_TOPIC_0000002544372643"></a>

Visit the [open-source repository](https://gitcode.com/boostkit/rocksdb/tree/rocksdb-v6.1.2-patch/docs) to view or download required documents.
