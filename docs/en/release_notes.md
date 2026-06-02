# Release Notes<a name="EN-US_TOPIC_0000002521309484"></a>

## Version Mapping<a name="EN-US_TOPIC_0000002521463536"></a>

### Product Version Information<a name="EN-US_TOPIC_0000002521463606"></a>

<table><tbody>
<tr>
    <th>Product Name</th>
    <td>Kunpeng BoostKit</td>
</tr>
<tr>
    <th>Product Version</th>
    <td>25.3.0</td>
</tr>
<tr>
    <th>Feature Name</th>
    <td>Metadata Acceleration</td>
</tr>
</tbody></table>

### Software Version Mapping<a name="EN-US_TOPIC_0000002521623612"></a>

| Software Type   | Version                                                                             |
|---------|---------------------------------------------------------------------------------|
| OS      | openEuler 22.03 LTS SP1 <br> openEuler 22.03 LTS SP2 <br> Debian GNU/Linux 10 |
| RocksDB | 6.1.2 <br> 7.9.2 <br> 8.3.3                                                   |

### Hardware Version Mapping<a name="EN-US_TOPIC_0000002552663559"></a>

| Project | Requirement                                         |
|-----|---------------------------------------------|
| Processor| Kunpeng 920<br>New Kunpeng 920 processor model<br>Kunpeng 950|

### Virus Scan Results<a name="EN-US_TOPIC_0000002521463602"></a>

Virus scanning is not involved because no software package is released.

## v1.1.0<a name="EN-US_TOPIC_0000002521623548"></a>

### Change Description<a name="EN-US_TOPIC_0000002552663493"></a>

Added support for ZSTD hardware offload by RocksDB.

### Resolved Issues<a name="EN-US_TOPIC_0000002552623511"></a>

None

### Known Issues<a name="EN-US_TOPIC_0000002521623546"></a>

None

## v1.0.0<a name="EN-US_TOPIC_0000002521623548"></a>

### Change Description<a name="EN-US_TOPIC_0000002552663493"></a>

This is the first official release.

Based on RocksDB, this feature uses a Huawei-developed algorithm to enable Kunpeng acceleration for better storage performance. This feature fits well with the Kunpeng architecture to optimize read and write hotspots, adjust background tasks (data flushing and compaction) based on service loads, and optimize cache logic based on data hotspots. The main features include memcpy optimization, RocksDB configuration parameter optimization, and CRC32 optimization.

### Resolved Issues<a name="EN-US_TOPIC_0000002552623511"></a>

None

### Known Issues<a name="EN-US_TOPIC_0000002521623546"></a>

None

## Related Documentation<a name="EN-US_TOPIC_0000002521463604"></a>

### Documentation<a name="EN-US_TOPIC_0000002552623581"></a>

| Document         | Description               | Delivery Method|
|---------------|---------------------|------|
| *Metadata Acceleration Release Notes*| Provides release information about metadata acceleration. | Open-source repository |
| *Metadata Acceleration Installation Guide* | Describes how to install and deploy metadata acceleration.| Open-source repository |

### Obtaining Documentation<a name="EN-US_TOPIC_0000002521623614"></a>

Visit the [open-source repository](https://gitcode.com/boostkit/rocksdb) to view or download related documents.
