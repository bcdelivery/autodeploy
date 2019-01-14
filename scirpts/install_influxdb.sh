#! /bin/sh
#######################
# DATAPATH: 数据路径
# VERSION: 版本
# S3_INSTALL_BUCKET：s3安装路径，例如http://169.254.169.254:8683/bingoinstall
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

# 判断${DATAPATH}是否存在此文件夹，不存在则创建
mkdir -p "${DATAPATH}"
if [ ! -d "${DATAPATH}" ]; then 
  echo "创建文件夹${DATAPATH}失败，请检查确认权限"
  exit 1
fi 

#下载安装文件
echo "下载安装文件"
wget -q ${S3_INSTALL_BUCKET}/influxdb-${VERSION}.zip -O ${DATAPATH}/influxdb-${VERSION}.zip
if [ ! -f "${DATAPATH}/influxdb-${VERSION}.zip" ]; then 
  echo "下载失败，请检查${S3_INSTALL_BUCKET}/influxdb-${VERSION}.zip文件是否存在"
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

# 解压influxdb-${VERSION}.zip
echo "解压influxdb-${VERSION}.zip文件"
cd ${DATAPATH}
unzip -q influxdb-${VERSION}.zip
rm -rf influxdb-${VERSION}.zip
cd influxdb-${VERSION}

# 安装influxdb
yum install ./$Release/influxdb-${VERSION}.x86_64.rpm
#修改配置文件config/server.properties
sed -i "s/^advertised.host.name/advertised.host.name=${outputs.kafka.privateIp}/g" config/server.properties
sed -i "s/^log.dirs/log.dirs=${LOGPATH}/g" config/server.properties
sed -i "s/^zookeeper.connect/zookeeper.connect=${ZKURL}/g" config/server.properties
sed -i "s/^delete.topic.enable/delete.topic.enable=true/g" config/server.properties
sed -i "s/^auto.create.topics.enable/auto.create.topics.enable=false/g" config/server.properties
sed -i "s/^listeners/listeners=PLAINTEXT:\/\/:9092/g" config/server.properties
# 如果是集群需要写入集群信息
if [ ${NUMOFSERVER} -ne 1 ] ;then 
  # 当前序列号是loopCounter,变量是从0开始，页面显示是从1开始 #SIPBug
  # 创建myid 文件
  myid=`expr ${loopCounter} - 1`
  sed -i "s/^broker.id/broker.id=${myid}/g" config/server.properties
fi 



# 制作kafka启动服务脚本
echo "制作kafka启动服务脚本"
chmod +x ${LOGPATH}/kafka/kafka.sh
ln -s ${LOGPATH}/kafka/kafka.sh /etc/init.d/kafka
if [ $Release -eq "rhel6" ] ;then 
  chkconfig --add kafka
  chkconfig kafka on 
fi 
/etc/init.d/kafka start

# 当前服务数量
echo "当前服务数量"
jps -m
echo "kafka安装完成"
exit 0