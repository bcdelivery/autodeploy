# 脚本信息
 脚本名称： `linux_format_volume`
 脚本描述： linux服务器格式化存储卷，并挂载到实例上。每个存储卷都有序列号，序列号为卷ID。
 操作系统： linux * 32/64
 脚本变量：

 |变量名称|显示名称|变量类型|变量内容|备注|
 |------|-------|-------|------|----|
 |VOLUMEID|存储卷ID|text| |存储卷ID|
 |FSTYPE|文件系统类型|text| ext4|格式化的文件系统，ext4、ext3等|
 |MOUNTPOINT|挂载点|text| /data|挂载点，文件夹不存在会创建文件夹|
 |NEEDREBOOT|是否重启|text| true|如果发现存储卷不存在则重启虚拟机等待磁盘出现|

# 脚本内容
`VOLUMEID`默认会作为磁盘的序列号，所以在linux中查询磁盘的序列号可以唯一确定VOLUMEID对应的磁盘，并进行格式化。

[import lang="sh"](../scirpts/linux_format_volume.sh)