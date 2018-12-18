#!/bin/bash
clear
wget http://10.201.83.1:81/data/mongodb_repl.tar.gz -O /tmp/mongodb_repl.tar.gz
tar -zxvf /tmp/mongodb_repl.tar.gz -C /tmp
echo "tar done"
clear
# Some functions to make the below more readable
SCRIPTNAME=$(basename "$0")                                #当前脚本文件名
SCRIPTPATH=$(cd $(dirname "$0");pwd)                       #当前脚本所在绝对目录
MONGODHOME=${MONGODHOME}                                   #mongodb家目录
MONGODBPATH=${MONGODBPATH}                                 #mongodb数据库目录
MONGODCONFDIR=$MONGODHOME/conf                             #mongodb配置文件目录
MONGODLOGDIR=${MONGODLOGDIR}                               #mongodb日志目录
MONGODLOG=$MONGODLOGDIR/mongo.log                          #mongodb日志文件
MONGODB_PROGRAM=${MONGODB_PROGRAM}                         #mongodb安装程序
MONGODB_MANAGE=/lib/systemd/system/mongodb.service         #mongodb管理程序
MONGODB_TAR_DIR=${MONGODB_TAR_DIR}                         #mongodb安装临时目录
KEEPALIVED=${KEEPALIVED}                                   #keepalived-rpm包（s7版本）

#脚本是否执行正确
if [ $# != 0 ]
then
    echo "Usage: sh $SCRIPTPATH/$SCRIPTNAME"
	exit
fi

#Detection system version
#判断当前系统是6还是7系列
dec_sys_ver()
{
if [[ -f /etc/redhat-release ]]; then
  ver0="$(cat /etc/redhat-release |awk -Frelease '{print $2}' |awk '{print $1}')"
  ver="$(echo ${ver0%%.*})"
  if [ "$ver" = "7" ]; then
    Release="rhel7"
  else
    Release="other"
  fi
fi
}

#mongodb安装程序是否存在
cd $SCRIPTPATH
if [ ! -f "$MONGODB_PROGRAM" ];then
    echo "mongodb安装程序（$MONGODB_PROGRAM）不存在，且必须和脚本在同一目录下！"
    exit 1
fi

#优化系统
#/etc/security/limits.conf
grep -w "* - nofile 65536" /etc/security/limits.conf > /dev/null   #判断/etc/security/limits.conf是否已经含有nofile的配置
if [ $? -eq 0 ];then
    echo " is already configured nofile 65536." > /dev/null
else
    cat >> /etc/security/limits.conf << EOF
* - nofile 65536
EOF
fi

grep -w "* - nproc 65536" /etc/security/limits.conf > /dev/null   #判断/etc/security/limits.conf是否已经含有nproc的配置
if [ $? -eq 0 ];then
    echo " is already configured nproc 65536." > /dev/null
else
    cat >> /etc/security/limits.conf << EOF
* - nproc 65536
EOF
fi
#修改完毕后，关闭当前终端，重新登陆生效，使用ulimit -n验证。

#巨大内存页
echo 'never' > /sys/kernel/mm/transparent_hugepage/enabled
echo 'never' > /sys/kernel/mm/transparent_hugepage/defrag
grep -w "transparent_hugepage/enabled" /etc/rc.d/rc.local > /dev/null   #判断/etc/rc.d/rc.local是否已经含有巨大内存页的配置
if [ $? -eq 0 ];then
    echo " is already configured transparent_hugepage/enabled." > /dev/null
else
    cat >> /etc/rc.d/rc.local << "EOF"
echo 'never' > /sys/kernel/mm/transparent_hugepage/enabled
EOF
fi

grep -w "transparent_hugepage/defrag" /etc/rc.d/rc.local > /dev/null   #判断/etc/rc.d/rc.local是否已经含有巨大内存页的配置
if [ $? -eq 0 ];then
    echo " is already configured transparent_hugepage/defrag." > /dev/null
else
    cat >> /etc/rc.d/rc.local << "EOF"
echo 'never' > /sys/kernel/mm/transparent_hugepage/defrag
EOF
fi

#create dir log
#mongodb家目录
if [ -d "$MONGODHOME" ];then
	while true
	do
	clear
	read -p "$MONGODHOME文件夹已存在，是否删除？y/n" judge
	if [ "$judge" == "y" ];then
        rm -rf $MONGODHOME
        mkdir -p $MONGODHOME
        break
	elif [ "$judge" == "n" ];then
	    echo "必须删除才可安装！"
        exit 1
	else
	    echo "输入有误！"
        sleep 2s
	fi 
    done	
else
    mkdir -p $MONGODHOME
fi

#mongodb数据库目录
if [ -d "$MONGODBPATH" ];then
	while true
	do
	clear
	read -p "$MONGODBPATH文件夹已存在，是否删除？y/n" judge
	if [ "$judge" == "y" ];then
        rm -rf $MONGODBPATH
        mkdir -p $MONGODBPATH
        break
	elif [ "$judge" == "n" ];then
	    echo "必须删除才可安装！"
        exit 1
	else
	    echo "输入有误！"
        sleep 2s
	fi 
    done	
else
    mkdir -p $MONGODBPATH
fi

#mongodb日志目录
if [ -d "$MONGODLOGDIR" ];then
	while true
	do
	clear
	read -p "$MONGODLOGDIR文件夹已存在，是否删除？y/n" judge
	if [ "$judge" == "y" ];then
        rm -rf $MONGODLOGDIR
        mkdir -p $MONGODLOGDIR
        break
	elif [ "$judge" == "n" ];then
	    echo "必须删除才可安装！"
        exit 1
	else
	    echo "输入有误！"
        sleep 2s
	fi 
    done	
else
    mkdir -p $MONGODLOGDIR
fi

#mongodb配置文件目录
#该步骤其实前面已经将$MONGODHOME重建了，其实可以不用再判断，直接创建
mkdir -p $MONGODCONFDIR

#mongodb日志文件
if [ -d "$MONGODLOG" ];then
	while true
	do
	clear
	read -p "$MONGODLOG文件已存在，是否删除？y/n" judge
	if [ "$judge" == "y" ];then
        rm -rf $MONGODLOG
        touch $MONGODLOG
        break
	elif [ "$judge" == "n" ];then
	    echo "必须删除才可安装！"
        exit 1
	else
	    echo "输入有误！"
        sleep 2s
	fi 
    done	
else
    touch $MONGODLOG
fi

#install mongodb
#mongodb安装临时目录
if [ -d "$MONGODB_TAR_DIR" ];then
	while true
	do
	clear
	read -p "$MONGODB_TAR_DIR文件夹已存在，是否删除？y/n" judge
	if [ "$judge" == "y" ];then
        rm -rf $MONGODB_TAR_DIR
        mkdir -p $MONGODB_TAR_DIR
        break
	elif [ "$judge" == "n" ];then
	    echo "必须删除才可安装！"
        exit 1
	else
	    echo "输入有误！"
        sleep 2s
	fi 
    done	
else
    mkdir -p $MONGODB_TAR_DIR
fi

cd $SCRIPTPATH
tar -zxvf $MONGODB_PROGRAM -C $MONGODB_TAR_DIR    #解压mongodb安装程序到临时目录
tar_name=`ls $MONGODB_TAR_DIR | grep "mongo"`     #取得解压后mongodb的目录名
mv $MONGODB_TAR_DIR/$tar_name/* $MONGODHOME/.     #将数据移到mongodb的家目录
rm -rf $MONGODB_TAR_DIR                           #删除临时目录

#MongoDB variable
grep "$MONGODHOME/bin" /etc/profile > /dev/null   #判断/etc/profile是否已经含有mongodb的环境变量
if [ $? -eq 0 ];then
    echo "The MongoDB variable is already configured." > /dev/null
else
    echo "export PATH=$MONGODHOME/bin:$PATH" >> /etc/profile
    source /etc/profile
fi

#create mongodb config
#该步骤其实前面已经将$MONGODHOME重建了，其实可以不用再判断，直接创建
cat > $MONGODCONFDIR/mongo.conf << EOF    #注意，若这里的EOF是带了双引号的（“EOF”），则cat里面的变量无法传递进去
systemLog:
  destination: file
  logAppend: true
  path: $MONGODLOG
storage:
  dbPath: $MONGODBPATH
  journal:
    enabled: true
processManagement:
  fork: true
net:
  port: 27017
  bindIp: 0.0.0.0
replication:
  replSetName: mongo_repl
EOF

#config mongodb manage script
config_manage_script()
{
#这里暂时不用特定账户启动mongodb
#User=mongodb
#Group=mongodb
cat > $MONGODB_MANAGE << EOF
[Unit]
 
Description=mongodb 
After=network.target remote-fs.target nss-lookup.target
 
[Service]
Type=forking
ExecStart=/usr/local/mongodb/bin/mongod --config /usr/local/mongodb/conf/mongo.conf
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/usr/local/mongodb/bin/mongod --shutdown --config /usr/local/mongodb/conf/mongo.conf
PrivateTmp=true
  
[Install]
WantedBy=multi-user.target
EOF
#判断$MONGODHOME是否默认为/usr/local/mongodb
if [ $MONGODHOME == "/usr/local/mongodb" ];then
    echo "same ok" > /dev/null
else
    echo "The specified directory is inconsistent with the mongodb_manage" > /dev/null
    sed -i "s#/usr/local/mongodb#$MONGODHOME#g" $MONGODB_MANAGE > /dev/null    #修改mongodb管理程序的MONGOHOME目录为正确的
fi
chmod 754 $MONGODB_MANAGE
systemctl daemon-reload
echo "**********************************************************"
echo -e "\e[32mInit Manage Script Done\e[0m"
echo "How to manage MongoDB:"
echo "systemctl start|stop|restart|status|enable|disable mongodb"
echo "**********************************************************"
}

#init keepalived
#install keepalived nmap
yum install $KEEPALIVED nmap -y
if [ $? -eq 0 ];then
        echo "install keepalived nmap done" > /dev/null
    else
        echo "install keepalived nmap failed,maybe no yum"
        exit 1
fi
#init sysctl.conf
grep "arp_ignore" /etc/sysctl.conf > /dev/null   #判断/etc/sysctl.conf是否已经含有arp_ignore的配置
if [ $? -eq 0 ];then
    echo " is already configured arp_ignore." > /dev/null
else
    cat >> /etc/sysctl.conf << "EOF"
net.ipv4.conf.all.arp_ignore=1
net.ipv4.conf.lo.arp_ignore=1
EOF
fi

grep "arp_announce" /etc/sysctl.conf > /dev/null   #判断/etc/sysctl.conf是否已经含有arp_ignore的配置
if [ $? -eq 0 ];then
    echo " is already configured arp_announce." > /dev/null
else
    cat >> /etc/sysctl.conf << "EOF"
net.ipv4.conf.all.arp_announce=2
net.ipv4.conf.lo.arp_announce=2
EOF
fi

sysctl -p

#config keepalived
cat > /etc/keepalived/keepalived.conf << "EOF"
! Configuration File for keepalived
# Define the script used to check if mongod is running
vrrp_script chk_mongod {
    script "nmap localhost -p 27017 | grep "27017/tcp open"
    interval 2
    weight -30
}
# Define the script to see if the local node is the primary
vrrp_script chk_mongo_primary {
    script "bin_mongo --eval '(!!db.runCommand("ismaster")["ismaster"])?quit(0):quit(1)'"
    interval 2
    weight 20
}

vrrp_instance VI_1 {
    state BACKUP
    interface eth0
    virtual_router_id 66
    priority 100
    advert_int 1

    track_script
    {
        chk_mongod
        chk_mongo_primary
    }

    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        vip    #变量调用
    }
}
EOF
sed -i "s#bin_mongo#$MONGODHOME/bin/mongo#g" /etc/keepalived/keepalived.conf
sed -i 's/vip/${outputs.vip.privateIpAddress}/g' /etc/keepalived/keepalived.conf

#start mongodb and keepalived
config_manage_script
#useradd mongodb -s /sbin/nologin
#chown -R mongodb:mongodb $MONGODBPATH $MONGODHOME $MONGODLOGDIR
#su - mongodb -s /bin/bash
systemctl start mongodb
systemctl enable mongodb
sleep 5s
systemctl start keepalived
systemctl enable keepalived
exit 0
