# 目标
MySQL是一个关系型数据库管理系统，由瑞典MySQL AB 公司开发，目前属于 Oracle 旗下公司。MySQL 最流行的关系型数据库管理系统，在 WEB 应用方面MySQL是最好的 RDBMS (Relational Database Management System，关系数据库管理系统) 应用软件之一。

本文介绍Oracle Mysql5.X在RHEL6.x、CentOS6.X服务器上的安装过程。假设读者知道`sip`中如何创建自动化部署方案，本文只描述自动化部署方案内容，如何创建自动化部署方案请参考`sip`使用手册。

# 模型
![mysql单机版模型](../asset/mysql_single_model.png)
本模型分为5个步骤,包含2个并行分支：
* mysql安全组: 资源类型为`安全组`，编号为`mysql_sg`，端口信息为`tcp:22,3306,4444,4567,4568;udp:4567`
* 创建mysql实例：资源类型为`实例`, 编号为`mysql_instance`
* 并行分支1:
  - 数据盘：资源类型为`存储`, 编号为`data_volume`，实例ID为`${outputs.mysql_instance.instanceId}`,实例编号为`${outputs.mysql_instance.instanceCode}`
  - 挂载数据盘：资源类型为`通用脚本`, 脚本为`linux_format_volume`,编号为`mount_data_volume`，实例ID为`${outputs.mysql_instance.instanceId}`
* 并行分支2:
  - 数据盘：资源类型为`存储`, 编号为`backup_volume`，实例ID为`${outputs.mysql_instance.instanceId}`,实例编号为`${outputs.mysql_instance.instanceCode}`
  - 挂载数据盘：资源类型为`通用脚本`, 脚本为`linux_format_volume`,编号为`mount_backup_volume`，实例ID为`${outputs.mysql_instance.instanceId}`
* 安装mysql: 资源类型为`组件`, 编号为`install_mysql`，组件名称`mysql`,安装脚本为下面的脚本`install_mysql_single.sh`

# 文件准备
需要在S3的`bingoinstall`桶中将下列文件上传，并且开通下载能力。
* 5.6.40：`mysql-5.6.40.zip`(数据库安装文件，必须),这个安装包种集成了依赖的rpm包。

# 输入参数

* MYSQLDATAPATH: MYSQL数据路径
* MYSQLBACKUPPATH: MYSQL备份数据路径
* MYSQLCLUSTERNAME: MYSQL集群名称
* MYSQLROOTPASSWD: MYSQL ROOT密码
* MYSQLSSTPASSWD: MYSQL SST密码
* MYSQLBACKUPKEEP: MYSQL 备份保留周期
* MYSQLURL：s3安装路径，例如http://169.254.169.254:8683/bingoinstall/mysql-5.6.40.zip

[import lang:"json"](../parameters/parameters.mysql_single.5.6.40.json)
# 输出参数
[import lang:"json"](../parameters/outputs.mysql_single.5.6.40.json)

# 脚本内容

## install_mysql_single.sh
[import lang:"sh"](../scirpts/install_mysql_single.sh)
