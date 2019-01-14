#! /bin/sh
#######################
# LOGPATH: 日志路径
# NUMOFSERVER: 服务器数量
# ZKURL: zookeeper服务器地址，例如10.201.83.1:2181,10.201.83.2:2181,10.201.83.3:2181
# TOPIC: 生产者topic
# VERSION: 版本
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
privateIpStr="${outputs.multi.kafka.privateIp}"
# 去掉前面的'['
privateIpStr=${privateIpStr#[}
# 去掉后面的']'
privateIpStr=${privateIpStr%]}
# 将','替换成空格
privateIpArr=(${privateIpStr//,/ })

echo "获取所有机器的机器ID"
# 返回的数据格式类似[i-abcdefg1,i-abcdefg2,i-abcdefg3]
instanceIdStr="${outputs.multi.kafka.instanceCode}"
# 去掉前面的'['
instanceIdStr=${instanceIdStr#[}
# 去掉后面的']'
instanceIdStr=${instanceIdStr%]}
# 将','替换成空格
instanceIdArr=(${instanceIdStr//,/ })

# check NUMOFSERVER >= 1
if [ ${NUMOFSERVER} -lt 1 ]; then 
  echo "kafka的数量至少为1，不超过9，推荐为奇数个"
  exit 1
fi 

# zk数量-1 ，为了产生seq
numofserver=$(expr ${NUMOFSERVER} - 1)
echo "设置host文件"
for i in `seq 0 $numofserver`;do 
  echo -e ${privateIpArr[$i]} '\t'  ${instanceIdArr[$i]}>>/etc/hosts
done

# 判断${LOGPATH}是否存在此文件夹，不存在则创建
mkdir -p "${LOGPATH}"
if [ ! -d "${LOGPATH}" ]; then 
  echo "创建文件夹${LOGPATH}失败，请检查确认权限"
  exit 1
fi 

#下载安装文件
echo "下载安装文件"
wget -q ${S3_INSTALL_BUCKET}/kafka_${VERSION}.tgz -O ${LOGPATH}/kafka_${VERSION}.tgz
if [ ! -f "${LOGPATH}/kafka_${VERSION}.tgz" ]; then 
  echo "下载失败，请检查${S3_INSTALL_BUCKET}/kafka_${VERSION}.tgz文件是否存在"
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

# 解压kafka_${VERSION}.tgz
echo "解压kafka_${VERSION}.tgz文件"
cd ${LOGPATH}
tar -xzf "kafka_${VERSION}.tgz"
mv kafka_${VERSION} kafka
rm -rf kafka_${VERSION}.tgz
cd kafka

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

# 设置环境变量
echo "设置环境变量"
echo 'export PATH=${LOGPATH}/kafka/bin:$PATH' >> /etc/profile

# 创建topic
echo "创建topic:${TOPIC}"
${LOGPATH}/kafka/bin/kafka-topics.sh --create --zookeeper ${ZKURL} --replication-factor ${NUMOFSERVER} --partitions 1 --topic ${TOPIC}
# 查看topic
echo "查看topic"
${LOGPATH}/kafka/bin/kafka-topics.sh --list --zookeeper ${ZKURL}
# 生成kafka启动脚本
echo "生成kafka启动脚本"
cat <<"EOF" >${LOGPATH}/kafka/kafka.sh
#! /bin/sh
# /etc/init.d/kafka: start the kafka daemon.
# chkconfig: - 80 20
# description: kafka
KAFKA_HOME=${LOGPATH}/kafka
KAFKA_USER=root
KAFKA_SCRIPT=$KAFKA_HOME/bin/kafka-server-start.sh
KAFKA_CONFIG=$KAFKA_HOME/config/server.properties
KAFKA_CONSOLE_LOG=/var/log/kafka/console.log
PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:${LOGPATH}/kafka/bin
prog=kafka
DESC="kafka daemon"
RETVAL=0
STARTUP_WAIT=30
SHUTDOWN_WAIT=30
KAFKA_PIDFILE=/var/run/kafka/kafka.pid
# Source function library.
. /etc/init.d/functions
start() {
echo -n $"Starting $prog: "
# Create pid file
if [ -f $KAFKA_PIDFILE ]; then
read ppid < $KAFKA_PIDFILE
if [ `ps --pid $ppid 2> /dev/null | grep -c $ppid 2> /dev/null` -eq '1' ]; then
  echo -n "$prog is already running"
  failure
  echo
  return 1
else
  rm -f $KAFKA_PIDFILE
fi
fi
        rm -f $KAFKA_CONSOLE_LOG
        mkdir -p $(dirname $KAFKA_PIDFILE)
        chown $KAFKA_USER $(dirname $KAFKA_PIDFILE) || true
# Run daemon
cd $KAFKA_HOME
        nohup sh $KAFKA_SCRIPT $KAFKA_CONFIG 2>&1 >> $KAFKA_CONSOLE_LOG 2>&1 &
        PID=$!
echo $PID > $KAFKA_PIDFILE
        count=0
        launched=false
until [ $count -gt $STARTUP_WAIT ]
do
                grep 'started' $KAFKA_CONSOLE_LOG > /dev/null
if [ $? -eq 0 ] ; then
                        launched=true
break
fi
                sleep 1
let count=$count+1;
done
        success
echo
return 0
}
stop() {
echo -n $"Stopping $prog: "
        count=0;
if [ -f $KAFKA_PIDFILE ]; then
read kpid < $KAFKA_PIDFILE
let kwait=$SHUTDOWN_WAIT
# Try issuing SIGTERM
kill -15 $kpid
until [ `ps --pid $kpid 2> /dev/null | grep -c $kpid 2> /dev/null` -eq '0' ] || [ $count -gt $kwait ]
do
                        sleep 1
let count=$count+1;
done
if [ $count -gt $kwait ]; then
kill -9 $kpid
fi
fi
        rm -f $KAFKA_PIDFILE
        rm -f $KAFKA_CONSOLE_LOG
        success
echo
}
reload() {
        stop
        start
}
restart() {
        stop
        start
}
status() {
if [ -f $KAFKA_PIDFILE ]; then
read ppid < $KAFKA_PIDFILE
if [ `ps --pid $ppid 2> /dev/null | grep -c $ppid 2> /dev/null` -eq '1' ]; then
echo "$prog is running (pid $ppid)"
return 0
else
echo "$prog dead but pid file exists"
return 1
fi
fi
echo "$prog is not running"
return 3
}
case "$1" in
start)
        start
        ;;
stop)
        stop
        ;;
reload)
        reload
        ;;
restart)
        restart
        ;;
status)
        status
        ;;
*)
echo $"Usage: $0 {start|stop|reload|restart|status}"
exit 1
esac
exit $?
EOF

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