# Release Notes

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
