# 项目介绍<a name="ZH-CN_TOPIC_0000002475751541"></a>

元数据加速特性是华为自主研发，在RocksDB基础上优化后的存储引擎性能加速特性。

RocksDB起源于Facebook，是一款高性能、持久化的嵌入式kv（key value）存储引擎，广泛应用于各种大规模数据存储和处理场景，如互联网服务、分布式系统和数据分析等。元数据加速特性在RocksDB项目的基础上，结合华为自研算法进行了性能加速优化，在使能鲲鹏加速特性时可以获取更佳的性能。主要优化内容包括：深度融合鲲鹏架构优化读写热点、结合业务负载调整后台任务（flush,compaction）、结合数据热点优化缓存逻辑等。

# 版本说明<a name="ZH-CN_TOPIC_0000002442663630"></a>

**表 1**  版本说明

<a name="table154016110243"></a>
<table><thead align="left"><tr id="row74015192418"><th class="cellrowborder" valign="top" width="30.73%" id="mcps1.2.4.1.1"><p id="p12401515246"><a name="p12401515246"></a><a name="p12401515246"></a>鲲鹏RocksDB</p>
</th>
<th class="cellrowborder" valign="top" width="27.16%" id="mcps1.2.4.1.2"><p id="p1340117112414"><a name="p1340117112414"></a><a name="p1340117112414"></a>开源RocksDB</p>
</th>
<th class="cellrowborder" valign="top" width="42.11%" id="mcps1.2.4.1.3"><p id="p24012120244"><a name="p24012120244"></a><a name="p24012120244"></a>特性</p>
</th>
</tr>
</thead>
<tbody><tr id="row7401131102414"><td class="cellrowborder" valign="top" width="30.73%" headers="mcps1.2.4.1.1 "><p id="p17933892480"><a name="p17933892480"></a><a name="p17933892480"></a>rocksdb-7.9.2-lava</p>
</td>
<td class="cellrowborder" valign="top" width="27.16%" headers="mcps1.2.4.1.2 "><p id="p3498171013418"><a name="p3498171013418"></a><a name="p3498171013418"></a>rocksdb-7.9.2</p>
</td>
<td class="cellrowborder" valign="top" width="42.11%" headers="mcps1.2.4.1.3 "><p id="p1040216111241"><a name="p1040216111241"></a><a name="p1040216111241"></a>memcpy优化、KAE卸载优化、RocksDB配置参数优化</p>
</td>
</tr>
<tr id="row1033592412519"><td class="cellrowborder" valign="top" width="30.73%" headers="mcps1.2.4.1.1 "><p id="p6336122416517"><a name="p6336122416517"></a><a name="p6336122416517"></a>rocksdb-8.3.3-kae_zstd</p>
</td>
<td class="cellrowborder" valign="top" width="27.16%" headers="mcps1.2.4.1.2 "><p id="p13361024158"><a name="p13361024158"></a><a name="p13361024158"></a>rocksdb-8.3.3</p>
</td>
<td class="cellrowborder" valign="top" width="42.11%" headers="mcps1.2.4.1.3 "><p id="p155908431052"><a name="p155908431052"></a><a name="p155908431052"></a>memcpy优化、AKE卸载优化、RocksDB配置参数优化</p>
</td>
</tr>
</tbody>
</table>

# 环境部署<a name="ZH-CN_TOPIC_0000002442669386"></a>

参考鲲鹏社区元数据加速[编译RocksDB](https://www.hikunpeng.com/document/detail/zh/kunpengsdss/appAccelFeatures/metaaccel/kunpengMetadata_34_0004.html)章节。

1.  安装依赖。

    ```
    yum install -y cmake gcc gcc-c++ gflags-devel libstdc++-devel
    ```

2.  获取RocksDB源码。

    ```
    yum install git -y
    git config --global http.sslVerify false
    git clone https://gitee.com/kunpeng_compute/rocksdb.git
    cd rocksdb
    git checkout rocksdb-7.9.2-lava
    ```

3.  以Release模式编译RocksDB。

    ```
    sh build.sh
    ```

4.  安装RocksDB。

    ```
    cd ../build
    make install
    ```

5.  获取优化参数配置。

    ```
    cd ../config_file
    cat optimize_file
    ```

# 快速上手<a name="ZH-CN_TOPIC_0000002476029345"></a>

性能测试。

```
cd rocksdb/script
sh test_perf_all.sh
```

>**说明：** 
>-   全量用例执行需10小时左右，可通过修改第8行kv大小，第13行db数量减少或修改用例。
>-   默认读写路径为“/mnt/rocksdb\_data/test“，如需修改可编辑脚本test\_perf\_all.sh第二行basedir至指定路径，执行前请确保该路径存在。
>-   如需将设备挂载至指定路径，执行下述指令，其中nvme0n1根据具体设备名称修改。
>    ```
>    mkfs.ext4 /dev/nvme0n1
>    mount /dev/nvme0n1 /mnt/rocksdb_data/test
>    ```

# 贡献指南<a name="ZH-CN_TOPIC_0000002476109161"></a>

如果使用过程中有任何问题，或者需要反馈特性需求和bug报告，可以提交issues联系我们，具体贡献方法可参考[这里](https://gitcode.com/boostkit/community/blob/master/docs/contributor/contributing.md)。

# 免责声明<a name="ZH-CN_TOPIC_0000002442829254"></a>

此代码仓计划参与RocksDB软件开源，仅作RocksDB功能扩展/RocksDB性能提升，编码风格遵照原生开源软件，继承原生开源软件安全设计，不破坏原生开源软件设计及编码风格和方式，软件的任何漏洞与安全问题，均由相应的上游社区根据其漏洞和安全响应机制解决。请密切关注上游社区发布的通知和版本更新。鲲鹏计算社区对软件的漏洞及安全问题不承担任何责任。

# 许可证书<a name="ZH-CN_TOPIC_0000002442669390"></a>

Apache License

# 参考文档<a name="ZH-CN_TOPIC_0000002476029349"></a>

鲲鹏社区[元数据加速特性](https://www.hikunpeng.com/document/detail/zh/kunpengsdss/appAccelFeatures/metaaccel/kunpengMetadata_34_0004.html)章节。

