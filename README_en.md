# BoostKit RocksDB

## Project Brand Name

RocksDB

### Latest Updates

* [2026-03-30] Released `RocksDB CRC32 and filter optimization` V26.0.RC1. This feature uses CRC32, pmull hardware instructions, and SVE2 vector instructions to accelerate the verification efficiency, and optimizes the Bloom filter construction method to improve the system performance by more than 5% in high-concurrency scenarios.
* [2026-03-30] Released the `64 KB page-based RocksDB optimization` feature. This feature compiles the 64 KB page kernel to effectively reduce the TLB miss rate, and supports system page size checks when jemalloc is used, improving the system performance by more than 5%.

### Project Introduction

BoostKit RocksDB is a RocksDB optimization patch repository based on the Kunpeng platform. It provides:

- **CRC32 and filter optimization patches**: use CRC32, pmull hardware instructions, and SVE2 vector instructions to accelerate the verification efficiency, and optimize the Bloom filter algorithm to reduce invalid I/O operations.
- **64 KB page-based optimization patch**: uses the 64 KB kernel page size to reduce TLB cache misses, and optimizes the memory alignment policy to improve memory access efficiency.

All optimization features are provided in patch files. You need to apply the patches and compile the open-source RocksDB source code.

The repository documents are as follows:

| Document| Description| Link|
| --- | --- | --- |

| rocksdb_crc32_optimization_feature_guide | Principles and installation and configuration methods of the CRC32 optimization feature| [Feature Guide](docs/en/rocksdb_crc32_optimization_feature_guide.md)|
| rocksdb_filter_optimization_feature_guide | Principles and installation and configuration methods of the filter optimization feature| [Feature Guide](docs/en/rocksdb_filter_optimization_feature_guide.md)|
| _64kb_page_based_rocksdb_optimization_feature_guide_ | Principles, installation methods, and usage of the 64 KB page-based optimization feature| [Feature Guide](docs/en/64kb_page_based_rocksdb_optimization_feature_guide.md)|

### Directory Structure

```text
rocksdb-patch/
├── README.md                                                             # Entry to the repository overview, providing branch details and feature navigation
├── docs/en/
│   ├── rocksdb_release_notes.md            
# Release notes 
│   ├── rocksdb_crc32_optimization_feature_guide.md            # Principles and enabling guide of the CRC32 optimization feature
│   ├── rocksdb_filter_optimization_feature_guide.md            # Principles and enabling guide of the filter optimization feature
│   ├── 64kb_page_based_rocksdb_optimization_feature_guide.md             # Principles and enabling guide of the 64 KB page-based optimization feature
│   ├── figures/                                                          # Directory for document figures
│   │   ├── en-us_image_0000002516993780.png                              # CRC32 performance bottleneck
│   │   ├── en-us_performance_comparison_crc32_and_filter.png        # Performance comparison before and after CRC32 and filter optimization
│   │   └── en-us_performance_comparison_64kb.png                    # Performance comparison before and after 64 KB page-based optimization
│   └── public_sys-resources/                                             # Document icon resources
│       ├── icon-caution.gif                                              # Caution icon
│       ├── icon-danger.gif                                               # Danger icon
│       ├── icon-note.gif                                                 # Note icon
│       ├── icon-notice.gif                                               # Notice icon
│       ├── icon-tip.gif                                                  # Tip icon
│       └── icon-warning.gif                                              # Warning icon
├── 0001-crc32c-sve2-arm64-combined.patch                                 # CRC32 optimization patch (SVE2+pmull)
├── 0002-filter_opt_6_1_2_final.patch                                     # Filter optimization patch
└── 0001-64k-jemalloc-check.patch                                         # 64K page-based optimization patch
```

### Feature Introduction

<table>
<thead>
<tr>
<th>Category</th>
<th>Feature Name</th>
<th>Feature Document</th>
<th>Description</th>
</tr>
</thead>
<tbody>
<tr>
<td rowspan="2">Verification acceleration</td>
<td>CRC32 hardware instruction-based optimization</td>
<td><a href="docs/en/rocksdb_crc32_optimization_feature_guide.md">rocksdb_crc32_optimization_feature_guide.md</a></td>
<td>This feature uses CRC32, pmull hardware instructions, and SVE2 vector instructions to optimize CRC32 verification and calculation, eliminating CPU performance bottlenecks while improving I/O throughput.</td>
</tr>
<tr>
<td>Intelligent Bloom filter</td>
<td><a href="docs/en/rocksdb_filter_optimization_feature_guide.md">rocksdb_filter_optimization_feature_guide.md</a></td>
<td>In hot data scenarios, this feature dynamically increases the bitmap size of the Bloom filter to improve the accuracy and reduce the false positive rate and invalid drive I/O operations.</td>
</tr>
<tr>
<td>Memory page optimization</td>
<td>64 KB page-based optimization</td>
<td><a href="docs/en/64kb_page_based_rocksdb_optimization_feature_guide.md">64kb_page_based_rocksdb_optimization_feature_guide.md</a></td>
<td>This feature uses the 64 KB kernel page size to reduce TLB cache misses and page table levels, and optimizes the memory alignment policy to improve memory access efficiency. With this feature, the QPS is improved by more than 5%.</td>
</tr>
</tbody>
</table>

### RocksDB Compatibility Information

| Feature Version| Upstream Version| CPU | OS| GCC/Toolchain|
| --- | --- | --- | --- | --- |
| RocksDB CRC32 and filter optimization 26.0.RC1| RocksDB 6.1.2 | New Kunpeng 920 processor model or Kunpeng 950 processor| openEuler 22.03 LTS SP4 or openEuler 24.03 LTS SP3| GCC 10.3.1 |
| 64 KB page-based RocksDB optimization 26.0.RC1| RocksDB 6.1.2 | New Kunpeng 920 processor model or Kunpeng 950 processor| openEuler 22.03 LTS SP4 or openEuler 24.03 LTS SP3| GCC 10.3.1 |

### Constraints and Precautions

- The optimization features are provided in patch files, which needs to be integrated and compiled from the source code and cannot be directly installed using the RPM packages.
- CRC32 and filter optimization requires the CPU to support the CRC32 hardware instructions. You can run the `lscpu | grep Flags | grep crc32` command to check whether the CPU supports the CRC32 hardware instructions.
- To use the 64 KB page-based optimization feature, you need to recompile the kernel with the 64 KB page size and restart the OS using the new kernel. You can run the `getconf PAGESIZE` command to verify the page size. If the command output is `65536`, the 64 KB page size has been enabled.
- When compiling the CRC32 optimization, you need to add the compilation option `-march=armv8-a+crc`.
- When compiling RocksDB, you need to change `true` to `false` in line 38 in the `BlockBasedTableConfig.java` file.
- `DISABLE_JEMALLOC=1` must be specified in the compilation options. The related checks in the patches are used to control the compilation behavior of the C++ dynamic and static libraries.
- You are advised to enable the ASLR security protection in advance by running `echo 2 >/proc/sys/kernel/randomize_va_space`.
- Java 1.8.0 and related dependency packages (such as snappy, zlib, lz4, and zstd) must be installed.

### Feature Version Maintenance Strategy

| Feature| Current Version| Maintenance Status| Description|
| --- | --- | --- | --- |
| RocksDB CRC32 and filter optimization| 26.0.RC1 | Continuous maintenance| Provides optimization patches for the CRC32 hardware instructions and intelligent Bloom filter.|
| 64 KB page-based RocksDB optimization| 26.0.RC1 | Continuous maintenance| Provides the patch for jemalloc compatibility check.|

### Version Maintenance Strategy

| Version| Maintenance Strategy| Current Status| Next Status| EOL Date|
| --- | --- | --- | --- | --- |
| RocksDB 6.1.2 | Regular version| Maintenance| - | - |

### Performance Improvement

| Feature| Test Scenario| Dataset| Specifications| QPS Improvement|
| --- | --- | --- | --- | --- |
| RocksDB CRC32 and filter optimization| YCSB workloada, workloadc| Standard test dataset| 16 vCPUs| 5% on average|
| 64 KB page-based RocksDB optimization| YCSB workloada, workloadc| Standard test dataset| 16 vCPUs| 5% on average|

### Contribution Statement

You are welcome to contribute to the community. If you have any questions, suggestions, feature requirements, or bug reports, please submit:

- [Issues](https://gitcode.com/boostkit/rocksdb/issues)

For details about the contribution process, see:

- [BoostKit Community Contribution Guide](https://gitcode.com/boostkit/community/blob/master/docs/contributor/contributing.md)

You are also welcome to share insights in:

- [BoostKit Discussions](https://gitcode.com/boostkit/community/discussions)

### License

The documents of this project are licensed under CC-BY 4.0. For details, see [LICENSE](https://gitcode.com/boostkit/rocksdb/tree/rocksdb-v6.1.2-patch/docs/LICENSE).
