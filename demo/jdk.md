# 脚本信息
 脚本名称： `LINUX_JRE_8U181_64`
 脚本描述： 在linux环境安装部署Oracle JDK 8u181，并配置环境变量.
 操作系统： linux * 64
 脚本变量：

 |变量名称|显示名称|变量类型|变量内容|备注|
 |------|-------|-------|------|----|
 |S3_INSTALL_BUCKET|安装文件url路径|text| |http://169.254.169.254:8683/bingoinstall|


# 脚本内容
`VOLUMEID`默认会作为磁盘的序列号，所以在linux中查询磁盘的序列号可以唯一确定VOLUMEID对应的磁盘，并进行格式化。

[import lang="sh"](../scirpts/install_java.sh)