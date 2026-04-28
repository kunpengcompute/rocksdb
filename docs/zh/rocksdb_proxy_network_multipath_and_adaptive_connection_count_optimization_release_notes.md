# RocksDB proxy网络多路径及自适应连接数优化 版本说明书

## 版本配套说明<a name="ZH-CN_TOPIC_0000002514512236"></a>

### 产品版本信息<a name="ZH-CN_TOPIC_0000002545952193"></a>

<a name="table62675726"></a>
<table><tbody><tr id="row41561572"><th class="firstcol" valign="top" width="26.61%" id="mcps1.1.3.1.1"><p id="p11044137"><a name="p11044137"></a><a name="p11044137"></a>产品名称</p>
</th>
<td class="cellrowborder" valign="top" width="73.39%" headers="mcps1.1.3.1.1 "><p id="p243mcpsimp"><a name="p243mcpsimp"></a><a name="p243mcpsimp"></a>Kunpeng BoostKit</p>
</td>
</tr>
<tr id="row33192131"><th class="firstcol" valign="top" width="26.61%" id="mcps1.1.3.2.1"><p id="p4208106"><a name="p4208106"></a><a name="p4208106"></a>产品版本</p>
</th>
<td class="cellrowborder" valign="top" width="73.39%" headers="mcps1.1.3.2.1 "><p id="p248mcpsimp"><a name="p248mcpsimp"></a><a name="p248mcpsimp"></a>26.1.RC1</p>
</td>
</tr>
<tr id="row24726251"><th class="firstcol" valign="top" width="26.61%" id="mcps1.1.3.3.1"><p id="p56669300"><a name="p56669300"></a><a name="p56669300"></a>特性名称</p>
</th>
<td class="cellrowborder" valign="top" width="73.39%" headers="mcps1.1.3.3.1 "><p id="p11923034"><a name="p11923034"></a><a name="p11923034"></a>RocksDB proxy网络多路径及自适应连接数优化</p>
</td>
</tr>
</tbody>
</table>


### 软件版本配套说明<a name="ZH-CN_TOPIC_0000002514352322"></a>

|软件类型|版本|
|--|--|
|OS|openEuler 22.03 LTS SP4|
|Kvrocks|2.2.0|



### 硬件版本配套说明<a name="ZH-CN_TOPIC_0000002514352320"></a>

|项目|要求|
|--|--|
|处理器|鲲鹏920新型号处理器|



### 病毒扫描结果<a name="ZH-CN_TOPIC_0000002545832185"></a>

不涉及软件包发布，不涉及病毒扫描。



## v26.1.RC1<a name="ZH-CN_TOPIC_0000002545832189"></a>

### 更新说明<a name="ZH-CN_TOPIC_0000002545952195"></a>

为了提升RocksDB在鲲鹏服务器中的整体性能表现与系统稳定性，鲲鹏BoostKit数据库使能套件新增RocksDB proxy即Kvrocks网络多路径及自适应连接数优化，该特性通过识别特定业务进程的流量特征，将指定业务进程的网络流量优先由当前业务进程所在NUMA上的网卡队列进行接收，从而实现业务进程网络请求与网络中断的亲和性。


### 已解决的问题<a name="ZH-CN_TOPIC_0000002514512234"></a>

无


### 遗留问题<a name="ZH-CN_TOPIC_0000002545832191"></a>

无



## 版本配套文档<a name="ZH-CN_TOPIC_0000002545832187"></a>

### 版本配套文档<a name="ZH-CN_TOPIC_0000002545952191"></a>

| 文档名称                                                          | 内容简介                                           | 交付形式 |
| ------------------------------------------------------------- | ---------------------------------------------- | ---- |
| 《Kunpeng BoostKit 26.1.RC1 RocksDB proxy网络多路径及自适应连接数优化 版本说明书》 | 本文档提供RocksDB proxy网络多路径及自适应连接数优化特性的版本发布及其配套信息。 | 开源仓  |
| 《Kunpeng BoostKit 26.1.RC1 RocksDB proxy网络多路径及自适应连接数优化 特性指南》  | 本文档提供RocksDB proxy网络多路径及自适应连接数优化的环境要求、特性使能指导。  | 开源仓  |



### 获取文档的方法<a name="ZH-CN_TOPIC_0000002514352318"></a>

您可以通过访问[开源仓](https://gitcode.com/boostkit/rocksdb/tree/rocksdb-v6.1.2-patch/docs/zh)浏览和获取相关文档。



