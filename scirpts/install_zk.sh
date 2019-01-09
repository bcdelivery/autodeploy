#! /bin/sh
#######################
# ZKDATAPATH: 数据路径
# ZKLOGPATH: 日志路径
# ZKENABLEADMIN: 是否启用管理员
# ZKADMIN:  管理员用户名
# ZKPASS: 管理员密码
# NUMOFZK: 服务器数量
# ZKVERSION: 版本
# S3_INSTALL_BUCKET：s3安装路径，例如http://169.254.169.254:8683/bingoinstall/
#######################
if [[ -f /etc/redhat-release ]]; then
  ver0="$(cat /etc/redhat-release |awk -Frelease '{print $2}' |awk '{print $1}')"
  ver="$(echo ${ver0%%.*})"
  if [ "$ver" = "7" ]; then
    Release="rhel7"
  elif [ "$ver" = "6" ]; then
    Release="rhel6"
  else
    echo "不支持的操作系统，需要使用centos或者rhel6、7版本"
    exit 1
  fi
else
    echo "不支持的操作系统，需要使用centos或者rhel6、7版本"
    exit 1
fi

echo "获取所有机器的私有IP"
# 返回的数据格式类似[192.168.1.10,192.168.1.11,192.168.1.12]
privateIpStr="${outputs.multi.zookeeper.privateIp}"
# 去掉前面的'['
privateIpStr=${privateIpStr#[}
# 去掉后面的']'
privateIpStr=${privateIpStr%]}
# 将','替换成空格
privateIpArr=(${privateIpStr//,/ })

echo "获取所有机器的机器ID"
# 返回的数据格式类似[i-abcdefg1,i-abcdefg2,i-abcdefg3]
instanceIdStr="${outputs.multi.zookeeper.instanceCode}"
# 去掉前面的'['
instanceIdStr=${instanceIdStr#[}
# 去掉后面的']'
instanceIdStr=${instanceIdStr%]}
# 将','替换成空格
instanceIdArr=(${instanceIdStr//,/ })

# check NUMOFZK >= 1
if [ ${NUMOFZK} -lt 1 ]; then 
  echo "zookeeper的数量至少为1，不超过9，推荐为奇数个"
  exit 1
fi 

# zk数量-1 ，为了产生seq
numofzk=$(expr ${NUMOFZK} - 1)
echo "设置host文件"
for i in `seq 0 $numofzk`;do 
  echo -e ${privateIpArr[$i]} '\t'  ${instanceIdArr[$i]}>>/etc/hosts
done

# 判断${ZKDATAPATH}是否存在此文件夹，不存在则创建
mkdir -p "${ZKDATAPATH}"
if [ ! -d "${ZKDATAPATH}" ]; then 
  echo "创建文件夹${ZKDATAPATH}失败，请检查确认权限"
  exit 1
fi 

# 判断${ZKLOGPATH}是否存在此文件夹，不存在则创建
mkdir -p "${ZKLOGPATH}"
if [ ! -d "${ZKLOGPATH}" ]; then 
  echo "创建文件夹${ZKLOGPATH}失败，请检查确认权限"
  exit 1
fi 

#下载安装文件
echo "下载安装文件"
wget -q ${S3_INSTALL_BUCKET}/zookeeper-${ZKVERSION}.tar.gz -O ${ZKDATAPATH}/zookeeper-${ZKVERSION}.tar.gz
if [ ! -f "${ZKDATAPATH}/zookeeper-${ZKVERSION}.tar.gz" ]; then 
  echo "下载失败，请检查${S3_INSTALL_BUCKET}/zookeeper-${ZKVERSION}.tar.gz文件是否存在"
  exit 1
fi

echo "修改内核文件"
mkdir -p "/etc/sysctl.d"
if [ ! -d "/etc/sysctl.d" ]; then 
  echo "创建文件夹/etc/sysctl.d失败，请检查确认权限"
  exit 1
fi 

cat <<EOF >/etc/sysctl.d/97-sysctl.conf
net.ipv4.tcp_syncookies = 0
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_synack_retries = 3
net.ipv4.tcp_syn_retries = 3
net.ipv4.tcp_rfc1337 = 1
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.conf.all.log_martians = 1
net.ipv4.tcp_ecn = 0
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_fack = 1
net.ipv4.tcp_dsack = 1
net.ipv4.ip_forward = 0
net.ipv4.conf.default.rp_filter = 0
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_max_syn_backlog = 20000
net.ipv4.tcp_orphan_retries = 1
net.ipv4.tcp_fin_timeout = 20
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_moderate_rcvbuf = 1
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 2500
net.core.somaxconn = 65000
EOF

# Reload the networking settings
/sbin/sysctl -p /etc/sysctl.d/97-sysctl.conf

# 解压zookeeper-${ZKVERSION}.tar.gz
echo "解压zookeeper-${ZKVERSION}.tar.gz文件"
cd ${ZKDATAPATH}
tar -xzf "zookeeper-${ZKVERSION}.tar.gz"
mv zookeeper-${ZKVERSION} zookeeper
rm -rf zookeeper-${ZKVERSION}.tar.gz
cd zookeeper

#修改配置文件
cp conf/zoo_sample.cfg conf/zoo.cfg
sed -i "/^dataDir/d" conf/zoo.cfg
sed -i "/^dataLogDir/d" conf/zoo.cfg
sed -i "/^#maxClientCnxns/d" conf/zoo.cfg
echo "dataDir=${ZKDATAPATH}" >>conf/zoo.cfg
echo "dataLogDir=${ZKLOGPATH}" >> conf/zoo.cfg
echo "maxClientCnxns=0" >> conf/zoo.cfg
# 如果是集群需要写入集群信息
if [ ${NUMOFZK} -ne 1 ] ;then 
  for i in `seq 0 $numofzk`;do 
    echo -e  "server.$i=${instanceIdArr[$i]}:2888:3888" >> conf/zoo.cfg
  done
  # 当前序列号是loopCounter,变量是从0开始，页面显示是从1开始 #SIPBug
  # 创建myid 文件
  echo `expr ${loopCounter} - 1` > ${ZKDATAPATH}/myid
fi 

# 按天出zookeeper日志，避免zookeeper.out文件过大
echo "修改zkEnv.sh文件日志输出方式从CONSOLE改为ROLLINGFILE"
sed -i "s/^    ZOO_LOG4J_PROP=\"INFO,CONSOLE\"/    ZOO_LOG4J_PROP=\"INFO,ROLLINGFILE\"/g" bin/zkEnv.sh

# 更换日志为滚动模式
sed -i "s/^zookeeper.root.logger=INFO, CONSOLE/zookeeper.root.logger=INFO, ROLLINGFIL/g" conf/log4j.properties
# 每日滚动
sed -i "s/^log4j.appender.ROLLINGFILE=org.apache.log4j.RollingFileAppender/log4j.appender.ROLLINGFILE=org.apache.log4j.DailyRollingFileAppender/g" conf/log4j.properties
# 文件格式
sed -i "/^log4j.appender.ROLLINGFILE.File=/alog4j.appender.ROLLINGFILE.DatePattern='.'yyyy-MM-dd" conf/log4j.properties
# 设置环境变量
echo "设置环境变量"
echo 'export PATH=${ZKDATAPATH}/zookeeper/bin:$PATH' >> /etc/profile

# 生成zookeeper启动脚本
echo "生成zookeeper启动脚本"
cat <<"EOF" >${ZKDATAPATH}/zookeeper/zookeeper.sh
#!/bin/sh
# Purpose: This script starts and stops the Zookeeper daemon
# chkconfig: - 90 10
# description: Zookeeper daemon
# Source function library
. /etc/init.d/functions
APP=${ZKDATAPATH}/zookeeper/bin/zkServer.sh
app(){
	$APP $1
}
error(){
echo -e "Error: Parameter non valide !"
echo -e "Usage: $0 {start | stop | restart | status}"
exit 1
}
usage(){
echo -e "Usage: $0 {start | stop | restart | status}"
echo ""
}
start(){
echo -e "Starting Zookeeper"
	app start
echo -e "Done"
}
stop(){
echo -e "Stopping Zookeeper"
    app stop
echo -e "Done"
}
restart(){
echo -e "Restarting Zookeeper"
	app stop
	sleep 5
	app start
echo -e "Done"
}
status(){
echo -e "Zookeeper status"
	app status
}
case "$1" in
	start)  
		start 
		;;
	stop)   
		stop 
		;;
	status) 
		status
		;;
	restart) 
		restart
		;;
	help) 
		usage 
		;;
*) 
		error 
		;;
esac
exit 0
EOF

# 制作zookeeper启动服务脚本
echo "制作zookeeper启动服务脚本"
chmod +x ${ZKDATAPATH}/zookeeper/zookeeper.sh
ln -s ${ZKDATAPATH}/zookeeper/zookeeper.sh /etc/init.d/zookeeper
if [ $Release -eq "rhel6" ] ;then 
  chkconfig --add zookeeper
  chkconfig zookeeper on 
fi 
/etc/init.d/zookeeper start
 
echo "zookeeper安装完成"
exit 0