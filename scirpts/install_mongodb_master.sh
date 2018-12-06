#!/bin/bash
clear
wget http://10.201.83.1:81/data/mongodb_ms.tar.gz -O /tmp/mongodb_ms.tar.gz
tar -zxvf /tmp/mongodb_ms.tar.gz -C /tmp
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
MONGODB_MANAGE=${MONGODB_MANAGE}                           #mongodb管理程序
MONGODB_TAR_DIR=${MONGODB_TAR_DIR}                         #mongodb安装临时目录
SSHPASS=${SSHPASS}                                         #sshpass安装包
KEEPALIVED6=${KEEPALIVED6}                                 #keepalived版本6
KEEPALIVED7=${KEEPALIVED7}                                 #keepalived版本7

#脚本是否执行正确
if [ $# != 0 ]
then
    echo "Usage: sh $SCRIPTPATH/$SCRIPTNAME"
	exit
fi

#判断当前系统版本
sys_ver()
{
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
}

#ssh config:为checkMongoDBport.sh的sshpass准备
sshconfig()
{
sed -i 's/.*UseDNS.*/UseDNS no/g' /etc/ssh/sshd_config > /dev/null 2>&1
sed -i 's/.*GSSAPIAuthentication.*/GSSAPIAuthentication no/g' /etc/ssh/sshd_config > /dev/null 2>&1
sed -i 's/.*GSSAPIAuthentication.*/GSSAPIAuthentication no/g' /etc/ssh/ssh_config > /dev/null 2>&1
sed -i 's/.*StrictHostKeyChecking.*/StrictHostKeyChecking no/g' /etc/ssh/ssh_config > /dev/null 2>&1
service sshd reload > /dev/null 2>&1
}

#mongodb安装程序是否存在
cd $SCRIPTPATH
if [ ! -f "$MONGODB_PROGRAM" ];then
    echo "mongodb安装程序（$MONGODB_PROGRAM）不存在，且必须和脚本在同一目录下！"
    exit 1
fi

#mongodb管理程序是否存在
cd $SCRIPTPATH
if [ ! -f "$MONGODB_MANAGE" ];then
    echo "mongodb管理程序（$MONGODB_MANAGE）不存在，且必须和脚本在同一目录下！"
    exit 1
fi

#sshpass安装包是否存在
cd $SCRIPTPATH
if [ ! -f "$SSHPASS" ];then
    echo "mongodb管理程序（$SSHPASS）不存在，且必须和脚本在同一目录下！"
    exit 1
fi

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

#mongodb配置文件目录（该步骤其实前面已经将$MONGODHOME重建了，其实可以不用再判断，可直接创建）
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

#解压mongodb安装程序并移动到家目录
cd $SCRIPTPATH
tar -zxvf $MONGODB_PROGRAM -C $MONGODB_TAR_DIR    #解压mongodb安装程序到临时目录
tar_name=`ls $MONGODB_TAR_DIR | grep "mongo"`     #取得解压后mongodb的目录名
mv $MONGODB_TAR_DIR/$tar_name/* $MONGODHOME/.     #将数据移到mongodb的家目录
rm -rf $MONGODB_TAR_DIR                           #删除临时目录

#MongoDB variable
grep "$MONGODHOME/bin" /etc/profile > /dev/null   #判断/etc/profile是否已经含有mongodb的环境变量
if [ $? -eq 0 ];then
    echo "The MongoDB variable is already configured." > /dev/null
	source /etc/profile
else
    echo "export PATH=$MONGODHOME/bin:$PATH" >> /etc/profile
    source /etc/profile
fi

#生成mongodb的配置文件
cat > $MONGODCONFDIR/mongo.conf << EOF    #注意，若这里的EOF是带了双引号的（“EOF”），则cat里面的变量无法传递进去
port=27017
dbpath=$MONGODBPATH
logpath=$MONGODLOG
fork=true
autoresync=true
logappend=true
nohttpinterface=true
EOF

#config ssh
sshconfig

#install keepalived nmap openssh openssh-clients
sys_ver
if [ "$Release" == "rhel6" ];then
    yum install $KEEPALIVED6 -y
    if [ $? -eq 0 ];then
        echo "install keepalived done" > /dev/null
    else
        echo "install keepalived failed,maybe no yum"
        exit 1
    fi
else
    yum install $KEEPALIVED7 -y
    if [ $? -eq 0 ];then
        echo "install keepalived done" > /dev/null
    else
        echo "install keepalived failed,maybe no yum"
        exit 1
    fi
fi
yum install nmap openssh openssh-clients -y
if [ $? -eq 0 ];then
    echo "install nmap openssh openssh-clients done" > /dev/null
else
    echo "install nmap openssh openssh-clients failed,maybe no yum"
    exit 1
fi

#heartbeat detection
rpm -ivh $SSHPASS
cat > $MONGODHOME/checkMongoDBport.sh << "EOF"
#!/bin/bash
#checkMongoDBport status
PORT=27017
HOST=slave_ip                    #变量调用
PASSWORD=slave_pass              #变量调用
nmap localhost -p $PORT | grep "$PORT/tcp open" > /dev/null
if [ $? -ne 0 ];then
    sleep 5
    nmap localhost -p $PORT | grep "$PORT/tcp open"
    if [ $? -ne 0 ];then
    /etc/init.d/mongod stop > /dev/null
    service keepalived stop
    grep -w "master" /usr/local/mongodb/flag > /dev/null    #判断当前角色，若为master，则执行下面的sshpass，若为slave，则不执行sshpass：
    if [ $? -eq 0 ];then
        sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no root@$HOST "/etc/init.d/mongod stop;echo "master" > /usr/local/mongodb/flag;/etc/init.d/mongod start_master"    #因为上述判断本机是master则远程是slave，此时需要远程的slave成为master
        fi
    fi
fi
EOF
sed -i 's/slave_ip/${outputs.slave.privateIp}/g' $MONGODHOME/checkMongoDBport.sh    #获取slave的ip和密码并填入checkMongoDBport.sh中
sed -i 's/slave_pass/${outputs.slave.password}/g' $MONGODHOME/checkMongoDBport.sh
chmod +x $MONGODHOME/checkMongoDBport.sh

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

vrrp_script checkMongoDBport
{
    script "/usr/local/mongodb/checkMongoDBport.sh"
    interval 3
    weight -20
}

vrrp_instance VI_1 {
    state BACKUP
	nopreempt
    interface eth0
    virtual_router_id 66
    priority 100
    advert_int 1

    track_script
    {
        checkMongoDBport
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
sed -i "s#/usr/local/mongodb#$MONGODHOME/g" /etc/keepalived/keepalived.conf
sed -i 's/vip/${outputs.vip.privateIpAddress}/g' /etc/keepalived/keepalived.conf

#config mongodb manage script
config_manage_script()
{
chmod a+x $MONGODB_MANAGE
cp $MONGODB_MANAGE $MONGODHOME/.
if [ -f "/etc/init.d/mongod" ];then    #问题：若该软链接的源文件被删除，这里if就将其判断为不存在，则在执行ln后，若源文件是其他名称，则无法创建软链接，见截图
	while true
	do
	clear
	read -p "/etc/init.d/mongod文件已存在，是否删除？y/n" judge
	if [ "$judge" == "y" ];then
        rm -rf /etc/init.d/mongod
        ln -s $MONGODHOME/mongodb_manage_ms.sh /etc/init.d/mongod
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
    ln -s $MONGODHOME/mongodb_manage_ms.sh /etc/init.d/mongod
fi
echo "****************************************************"
echo -e "\e[32mInit Done\e[0m"
echo "How to manage MongoDB:/etc/init.d/mongod start_master|start_slave|stop|status"
echo "****************************************************"
}

#config mongodb manage script
config_manage_script
#判断$MONGODHOME是否默认为/usr/local/mongodb
if [ $MONGODHOME == "/usr/local/mongodb" ];then
    echo "same ok" > /dev/null
else
    echo "The specified directory is inconsistent with the mongodb_manage" > /dev/null
    sed -i "6s#MONGOHOME.*#MONGOHOME=$MONGODHOME#" $MONGODB_MANAGE > /dev/null    #修改mongodb管理程序的MONGOHOME目录为正确的
fi
sed -i 's/master_ip/${outputs.master.privateIp}/g' $MONGODB_MANAGE

#start mongodb
#第一次启动master不能直接用：/etc/init.d/mongod start_master
#$MONGODHOME/bin/mongod -f $MONGODHOME/conf/mongo.conf --master;echo "master" > $MONGODHOME/flag
echo "master" > $MONGODHOME/flag
/etc/init.d/mongod start_master

#start keepalived
sleep 2s
service keepalived start
echo "Suggest:no set keepalived boot with system"
exit 0

