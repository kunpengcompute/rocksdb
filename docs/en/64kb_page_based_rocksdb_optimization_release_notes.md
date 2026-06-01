# 64 KB Page-based RocksDB Optimization Release Notes

## Version Mapping<a name="EN-US_TOPIC_0000002514512236"></a>

### Product Version Information<a name="EN-US_TOPIC_0000002545952193"></a>

<a name="table62675726"></a>
<table><tbody><tr id="row41561572"><th class="firstcol" valign="top" width="26.61%" id="mcps1.1.3.1.1"><p id="p11044137"><a name="p11044137"></a><a name="p11044137"></a>Product Name</p>
</th>
<td class="cellrowborder" valign="top" width="73.39%" headers="mcps1.1.3.1.1 "><p id="p243mcpsimp"><a name="p243mcpsimp"></a><a name="p243mcpsimp"></a>Kunpeng BoostKit</p>
</td>
</tr>
<tr id="row33192131"><th class="firstcol" valign="top" width="26.61%" id="mcps1.1.3.2.1"><p id="p4208106"><a name="p4208106"></a><a name="p4208106"></a>Product Version</p>
</th>
<td class="cellrowborder" valign="top" width="73.39%" headers="mcps1.1.3.2.1 "><p id="p248mcpsimp"><a name="p248mcpsimp"></a><a name="p248mcpsimp"></a>26.0.RC1</p>
</td>
</tr>
<tr id="row24726251"><th class="firstcol" valign="top" width="26.61%" id="mcps1.1.3.3.1"><p id="p56669300"><a name="p56669300"></a><a name="p56669300"></a>Feature Name</p>
</th>
<td class="cellrowborder" valign="top" width="73.39%" headers="mcps1.1.3.3.1 "><p id="p11923034"><a name="p11923034"></a><a name="p11923034"></a>64 KB page-based RocksDB optimization</p>
</td>
</tr>
</tbody>
</table>


### Software Version Mapping<a name="EN-US_TOPIC_0000002514352322"></a>

|Type|Version|
|--|--|
|OS|openEuler 22.03 LTS SP4 or openEuler 24.03 LTS SP3|
|RocksDB|6.1.2|



### Hardware Version Mapping<a name="EN-US_TOPIC_0000002514352320"></a>

|Item|Requirement|
|--|--|
|Processor|New Kunpeng 920 processor model or Kunpeng 950 processor|



### Virus Scan Results<a name="EN-US_TOPIC_0000002545832185"></a>

Virus scanning is not involved because no software package is released.



## v26.0.RC1<a name="EN-US_TOPIC_0000002545832189"></a>

### Change Description<a name="EN-US_TOPIC_0000002545952195"></a>

To improve the overall performance and system stability of RocksDB on Kunpeng servers, the 64 KB page-based RocksDB optimization feature is added to Kunpeng BoostKit for Database. This feature compiles the 64 KB page kernel to effectively reduce the TLB miss rate, and supports system page size checks when jemalloc is used.


### Resolved Issues<a name="EN-US_TOPIC_0000002514512234"></a>

None


### Known Issues<a name="EN-US_TOPIC_0000002545832191"></a>

None



## Related Documentation<a name="EN-US_TOPIC_0000002545832187"></a>

### Documentation<a name="EN-US_TOPIC_0000002545952191"></a>

|Document|Description|Delivery Method|
|--|--|--|
|*Kunpeng BoostKit 26.0.RC1 64 KB Page-based RocksDB Optimization Release Notes*|Describes the version release and mapping information of the 64 KB page-based RocksDB optimization feature.|Open-source repository|
|*Kunpeng BoostKit 26.0.RC1 64 KB Page-based RocksDB Optimization Feature Guide*|Describes the environment requirements and provides guidance on enabling the 64 KB page-based RocksDB optimization feature.|Open-source repository|



### Obtaining Documentation<a name="EN-US_TOPIC_0000002514352318"></a>

Visit the [open-source repository](https://gitcode.com/boostkit/rocksdb/tree/rocksdb-v6.1.2-patch/docs/en) to view or download required documents.
