#!/bin/bash
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
MONGODB_MANAGE=${MONGODB_MANAGE}                           #mongodb管理程序6
MONGODB_MANAGE7=${MONGODB_MANAGE7}                         #mongodb管理程序7
MONGODB_TAR_DIR=${MONGODB_TAR_DIR}                         #mongodb安装临时目录

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
cat /etc/redhat-release | grep "7" > /dev/null
if [ $? -eq 0 ];then
    echo "System is Series 7" > /dev/null
    sys_ver=7
else
    echo "System is Series 6" > /dev/null
    sys_ver=6
fi
}

#mongodb安装程序是否存在
cd $SCRIPTPATH
if [ ! -f "$MONGODB_PROGRAM" ];then
    echo "mongodb安装程序（$MONGODB_PROGRAM）不存在，且必须和脚本在同一目录下！"
    exit 1
fi

#mongodb管理程序是否存在（分系统）
dec_sys_ver
if [ $sys_ver -eq 7 ];then
    if [ ! -f "$MONGODB_MANAGE7" ];then
        echo "mongodb安装程序（$MONGODB_MANAGE7）不存在，且必须和脚本在同一目录下！"
        exit 1
    fi
else
    if [ ! -f "$MONGODB_MANAGE" ];then
        echo "mongodb安装程序（$MONGODB_MANAGE）不存在，且必须和脚本在同一目录下！"
        exit 1
    fi
fi

#if [ -f "$MONGODB_MANAGE7" ] || [ -f "$MONGODB_MANAGE7" ];then    #两个mongodb管理程序，针对6或7系列系统
#    echo "ok" > /dev/null
#else
#    echo "mongodb管理程序（$MONGODB_MANAGE或者$MONGODB_MANAGE7）不存在，且必须和脚本在同一目录下！"
#    exit 1
#fi

#判断$MONGODHOME是否默认为/usr/local/mongodb
if [ $MONGODHOME == "/usr/local/mongodb" ];then
    echo "same ok" > /dev/null
else
    echo "The specified directory is inconsistent with the mongodb_manage" > /dev/null
    sed -i "32s#MONGOHOME.*#MONGOHOME=$MONGODHOME#" $MONGODB_MANAGE > /dev/null    #修改mongodb管理程序的MONGOHOME目录为正确的
    sed -i "19s#MONGOHOME.*#MONGOHOME=$MONGODHOME#" $MONGODB_MANAGE7 > /dev/null
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
#if [ -d "$MONGODCONFDIR" ];then
#	while true
#	do
#	clear
#	read -p "$MONGODCONFDIR文件夹已存在，是否删除？y/n" judge
#	if [ "$judge" == "y" ];then
#        rm -rf $MONGODCONFDIR
#        mkdir -p $MONGODCONFDIR
#        break
#	elif [ "$judge" == "n" ];then
#	    echo "必须删除才可安装！"
#        exit 1
#	else
#	    echo "输入有误！"
#        sleep 2s
#	fi 
#    done	
#else
#    mkdir -p $MONGODCONFDIR
#fi
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
#if [ -f "$MONGODCONFDIR/mongo.conf" ];then
#	while true
#	do
#	clear
#	read -p "$MONGODCONFDIR/mongo.conf文件已存在，是否删除？y/n" judge
#	if [ "$judge" == "y" ];then
#        rm -rf $MONGODCONFDIR/mongo.conf
#        break
#	elif [ "$judge" == "n" ];then
#	    echo "必须删除才可安装！"
#        exit 1
#	else
#	    echo "输入有误！"
#        sleep 2s
#	fi 
#    done	
#else
#    cat > $MONGODCONFDIR/mongo.conf << EOF    #注意，若这里的EOF是带了双引号的（“EOF”），则cat里面的变量无法传递进去
#port=27017
#dbpath=$MONGODBPATH
#logpath=$MONGODLOG
#fork=true
#autoresync=true
#logappend=true
#nohttpinterface=true
#EOF
#fi
cat > $MONGODCONFDIR/mongo.conf << EOF    #注意，若这里的EOF是带了双引号的（“EOF”），则cat里面的变量无法传递进去
port=27017
dbpath=$MONGODBPATH
logpath=$MONGODLOG
fork=true
autoresync=true
logappend=true
nohttpinterface=true
EOF

#config mongodb manage script6
config_manage_script6()
{
chmod a+x $MONGODB_MANAGE
cp $MONGODB_MANAGE $MONGODHOME/.
if [ -f "/etc/init.d/mongod" ];then
	while true
	do
	clear
	read -p "/etc/init.d/mongod文件已存在，是否删除？y/n" judge
	if [ "$judge" == "y" ];then
        rm -rf /etc/init.d/mongod
        ln -s $MONGODHOME/mongodb_manage.sh /etc/init.d/mongod
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
    ln -s $MONGODHOME/mongodb_manage.sh /etc/init.d/mongod
fi
echo "****************************************************"
echo -e "\e[32mInit Done\e[0m"
echo "How to manage MongoDB:service mongod start|stop|restart|status"
echo "****************************************************"
}

#config mongodb manage script7
config_manage_script7()
{
chmod a+x $MONGODB_MANAGE7
cp $MONGODB_MANAGE7 $MONGODHOME/.
if [ -f "/etc/init.d/mongod" ];then    #问题：若该软链接的源文件被删除，这里if就将其判断为不存在，则在执行ln后，若源文件是其他名称，则无法创建软链接，见截图
	while true
	do
	clear
	read -p "/etc/init.d/mongod文件已存在，是否删除？y/n" judge
	if [ "$judge" == "y" ];then
        rm -rf /etc/init.d/mongod
        ln -s $MONGODHOME/mongodb_manage_rc7.sh /etc/init.d/mongod
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
    ln -s $MONGODHOME/mongodb_manage_rc7.sh /etc/init.d/mongod
fi
echo "****************************************************"
echo -e "\e[32mInit Done\e[0m"
echo "How to manage MongoDB:/etc/init.d/mongod start|stop|restart|status"
echo "****************************************************"
}

#start mongodb
dec_sys_ver
if [ $sys_ver -eq 7 ];then
    echo "System is Series 7" > /dev/null
    config_manage_script7
    /etc/init.d/mongod start
    grep "/etc/init.d/mongod start" /etc/rc.d/rc.local > /dev/null   #判断/etc/rc.d/rc.local是否已经设置开机自启
    if [ $? -eq 0 ];then
        echo "****************************************************"
        echo "Setting MongoDB boot with system ..."
        echo "The MongoDB is already configured boot with system."
        echo "****************************************************"
        chmod +x /etc/rc.d/rc.local
    else
        echo "/etc/init.d/mongod start" >> /etc/rc.d/rc.local
        echo "****************************************************"
        echo "Setting MongoDB boot with system Done"
        echo "****************************************************"
        chmod +x /etc/rc.d/rc.local
    fi
else
    echo "System is Series 6" > /dev/null
    config_manage_script6
    service mongod start
    chkconfig mongod on
    echo "****************************************************"
    echo "Setting MongoDB boot with system Done"
    echo "****************************************************"
fi

