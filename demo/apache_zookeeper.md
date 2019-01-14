# 目标
ZooKeeper是一个分布式的，开放源码的分布式应用程序协调服务，是Google的Chubby一个开源的实现，是Hadoop和Hbase的重要组件。它是一个为分布式应用提供一致性服务的软件，提供的功能包括：配置维护、域名服务、分布式同步、组服务等。ZooKeeper的目标就是封装好复杂易出错的关键服务，将简单易用的接口和性能高效、功能稳定的系统提供给用户。Zookeeper应用非常广泛，本文介绍Zookeeper自动化安装部署过程。

假设读者指导`sip`中如何创建自动化部署方案，本文只描述自动化部署方案内容，如何创建自动化部署方案请参考`sip`使用手册。

# 模型
![zookeeper版模型](../asset/apache_zookeeper_model.jpg)
本模型分为3个步骤，其中有2个子流程：
* 创建zookeeper安全组:资源类型为 `安全组`，编号为`zookeeper_sg`,开放端口为`tcp:22,2888,3888,${ZKPORT}`
* 创建实例子流程：资源类型为`子流程`, 多实例类型为`Parallel`, 基数为`${NUMOFZK}`
  - 创建实例：资源类型为`实例`, 编号为`zookeeper`
  - 申请zookeeper弹性IP：资源类型为`弹性IP`, 编号为`zookeeper_eip`，实例ID为`${outputs.zookeeper.instanceId}`
  - 安装JRE：资源类型为`通用指令`,编号为`install_jre`，实例ID为`${outputs.zookeeper.instanceId}`，脚本文件`LINUX_JRE_8U181_64`
  - 并行分支：基数(多实例)`${NUMOFZK}`,多实例类型`Parallel`
  - 并行分支1：申请zookeeper数据volume：资源类型为`存储`, 编号为`zk_data_volume`，实例ID为`${outputs.zookeeper.instanceId}`，实例编号为`${outputs.zookeeper.instanceCode}`
  - 并行分支1：格式化zookeeper数据volume：资源类型为`通用指令`,编号为`format_zk_data_volume`，实例ID为`${outputs.zookeeper.instanceId}`，脚本文件`linux_format_volume_new`
  - 并行分支2：申请zookeeper日志volume：资源类型为`存储`, 编号为`zk_log_volume`，实例ID为`${outputs.zookeeper.instanceId}`，实例编号为`${outputs.zookeeper.instanceCode}`
  - 并行分支2：格式化zookeeper日志volume：资源类型为`通用指令`,编号为`format_zk_log_volume`，实例ID为`${outputs.zookeeper.instanceId}`，脚本文件`linux_format_volume_new`
* 安装zookeeper子流程：资源类型为`子流程`, 多实例类型为`Parallel`, 基数为`${NUMOFZK}`
  - 安装zookeeper组件: 资源类型为`组件`, 编号为`zookeeper_com`，安装目录为`${ZKDATAPATH}`,日志目录为`${ZKLOGPATH}`,实例ID为`${outputs.zookeeper.instanceId}`,安装脚本为下面的脚本.

# 文件准备
需要在S3的`bingoinstall`桶中将下列文件上传，并且开通下载能力。
* 3.4.12：`zookeeper-3.4.12.tar.gz`(安装文件，必须)

以上文件可以在[https://zookeeper.apache.org](https://zookeeper.apache.org/releases.html)下载，请保持原样上传。

# 输入参数

* ZKDATAPATH: 数据路径
* ZKLOGPATH: 日志路径
* ZKENABLEADMIN: 是否启用管理员
* ZKADMIN:  管理员用户名
* ZKPORT: port
* ZKPASS: 管理员密码
* NUMOFZK: 服务器数量
* ZKVERSION: 版本
* S3_INSTALL_BUCKET：s3安装路径，例如http://169.254.169.254:8683/bingoinstall/

[import lang:"json"](../parameters/parameters.zk.3.4.12.json)
# 输出参数
[import lang:"json"](../parameters/outputs.zk.3.4.12.json)
# 服务使用
TODO: 增加描述使用
# 脚本内容

[import lang:"sh"](../scirpts/install_zk.sh)
