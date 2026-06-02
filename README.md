# README<a name="ZH-CN_TOPIC_0000002521561018"></a>

## 项目介绍<a name="ZH-CN_TOPIC_0000002551532807"></a>

元数据加速特性是华为自主研发，在RocksDB基础上优化后的存储引擎性能加速特性。

RocksDB是一款高性能、持久化的嵌入式kv（key value）存储引擎，广泛应用于各种大规模数据存储和处理场景，如互联网服务、分布式系统和数据分析等。元数据加速特性在RocksDB项目的基础上，结合华为自研算法进行了性能加速优化，在使能鲲鹏加速特性时可以获取更佳的性能。主要优化内容包括：深度融合鲲鹏架构优化读写热点、结合业务负载调整后台任务（flush，compaction）、结合数据热点优化缓存逻辑等。

## 目录结构<a name="ZH-CN_TOPIC_0000002551702481"></a>

```txt
├── docs                                    # 项目文档目录
│   ├── LICENSE                             # 文档许可协议
│   └── zh                                  # 中文文档目录
│       ├── figures                         # 中文文档图片资料目录
│       ├── public_sys-resources            # 中文公共资源目录
│       ├── installation_guide.md           # 安装指南
│       └── release_notes.md                # 版本说明书
├── 6.1.2-optimization.patch                # 软件许可协议
├── rocksdb-8.3.3-kae_zstd.patch            # 软件许可协议
├── LICENSE                                 # 软件许可协议
└── README.md                               # 介绍文档
```

## 版本说明<a name="ZH-CN_TOPIC_0000002520662482"></a>

版本信息请参见《[版本说明书](docs/zh/release_notes.md)》。

## 环境部署<a name="ZH-CN_TOPIC_0000002520502500"></a>

环境要求、编译安装指南请参见《[安装指南](docs/zh/installation_guide.md)》。


## 快速入门<a name="ZH-CN_TOPIC_0000002551662477"></a>

以rocksdb-8.3.3-kae_zstd分支为例，请参见《[安装指南](docs/zh/installation_guide.md)》完成环境部署。

1. 修改测试脚本。

    ```sh
    cd rocksdb/script
    vim test_perf_all.sh
    ```

    将第一行`num1`参数修改为`13421772`。

    ```sh
    num1=13421772 #总I/O数
    basedir="/mnt/rocksdb_data/test"
    prefix="../test_data/test_perf_cache10%_final"
    mkdir -p $basedir
    ...
    ```

2. 性能测试。
   ```sh
    sh test_perf_all.sh
    ```

**说明：** 

- 默认读写路径为`/mnt/rocksdb_data/test`，如需修改可编辑脚本`test_perf_all.sh`第二行basedir至指定路径，执行前请确保该路径存在。
- 如需将设备挂载至指定路径，执行下述指令，其中nvme0n1根据具体设备名称修改。

    ```sh
    mkfs.ext4 /dev/nvme0n1
    mount /dev/nvme0n1 /mnt/rocksdb_data/test
    ```



## 免责声明<a name="ZH-CN_TOPIC_0000002551702485"></a>

**致本项目使用者**

- 本项目仅供调试和开发之用，使用者需自行承担使用风险，并理解以下内容：
    - 数据处理及删除：用户在使用本工具过程中产生的数据属于用户责任范畴。建议用户在使用完毕后及时删除相关数据，以防信息泄露。
    - 数据保密与传播：使用者了解并同意不得将通过本工具产生的数据随意外发或传播。对于由此产生的信息泄露、数据泄露或其他不良后果，本工具及其开发者概不负责。
    - 用户输入安全性：用户需自行保证输入的命令行的安全性，并承担因输入不当而导致的任何安全风险或损失。对于输入命令行不当所导致的问题，本工具及其开发者概不负责。

- 免责声明范围：本免责声明适用于所有使用本工具的个人或实体。使用本工具即表示您同意并接受本声明的内容，并愿意承担因使用该功能而产生的风险和责任，如有异议请停止使用本工具。
- 在使用本工具之前，请**谨慎阅读并理解以上免责声明的内容**。对于使用本工具所产生的任何问题或疑问，请及时联系开发者。

**致数据所有者**

如果您不希望您的模型或数据集等信息在本项目中被提及，或希望更新本项目有关的描述，请在GitCode提交issue，我们将根据您的issue要求删除或更新您相关描述。衷心感谢您对本项目的理解和贡献。

## License<a name="ZH-CN_TOPIC_0000002520662484"></a>

本项目的代码适用于Apache License 2.0许可证，具体请参见[LICENSE文件](LICENSE)。

本项目的文档适用于CC-BY 4.0许可证，具体请参见[LICENSE文件](docs/LICENSE)。

## 贡献声明<a name="ZH-CN_TOPIC_0000002551662481"></a>

欢迎大家为社区做贡献，如果使用过程中有任何问题/建议，或者需要反馈特性需求和bug报告，可以提交[Issues](https://gitcode.com/boostkit/community/blob/master/docs/contributor/issue-submit.md)联系我们，具体贡献方法可参考[这里](https://gitcode.com/boostkit/community/blob/master/docs/contributor/contributing.md)。同时也欢迎大家在[讨论专区](https://gitcode.com/boostkit/community/discussions)展开讨论交流。感谢您的支持。
