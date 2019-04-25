#! /bin/sh
#######################
# ORACLEUSER: oracle用户
# GRIDUSER: grid用户
# ORACLEPATH: oracle安装路径
# ORACLESID: oracle sid
# ORACLEURL: oracle安装文件路径
# ORACLEPASSWD: oracle密码
# GRIDURL: grid安装文件路径
# ORACLE_VERSION: oracle安装版本，12.2.0.1，12.1.0.2
# GRID_PATCH: grid补丁文件包名称列表，英文逗号分隔
# ORACLE_PATCH: oracle补丁文件包名称列表，英文逗号分隔
# ORACLE_CHARACTER: oracle字符集
# INSTALLER_S3_BUCKET：s3路径，例如http://169.254.169.254:8683/bingoinstall
#######################
echo "设置hostname"
echo "${outputs.oracle_primary.privateIp}    ${outputs.oracle_primary.instanceCode} "  >>/etc/hosts
echo "${outputs.oracle_standby.privateIp}    ${outputs.oracle_standby.instanceCode} "  >>/etc/hosts

# 安全加固后的机器/tmp目录可能普通用户没有权限造成安装失败
chmod 777 /tmp

echo "优化内核参数"
cat <<EOF >/etc/sysctl.conf
vm.swappiness = 10
vm.vfs_cache_pressure = 50
fs.aio-max-nr = 1048576
fs.file-max = 6815744
kernel.shmall = 1073741824
kernel.shmmax = 4398046511104
kernel.shmmni = 4096
kernel.sem = 250 32000 100 128
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576
EOF
# 使内核配置信息生效
sysctl --system
echo "安装oracle需要依赖的软件包"
yum install unzip bc binutils compat-libcap1.x86_64 gcc gcc-c++ compat-libstdc++-33.x86_64 glibc glibc-devel ksh libaio libaio-devel libgcc libstdc++ libstdc++-devel libxcb libX11 libXau libXi libXtst libXrender make net-tools nfs-utils smartmontools sysstat -y
echo "创建用户"
groupadd -g 10001 oinstall
groupadd -g 10002 dba
groupadd -g 10003 oper
groupadd -g 10004 backupdba
groupadd -g 10005 dgdba
groupadd -g 10006 asmdba
groupadd -g 10007 asmoper
groupadd -g 10008 asmadmin

useradd -u 12001 -g oinstall -G asmadmin,asmdba,asmoper,dba  ${GRIDUSER}
useradd -u 12002 -g oinstall -G dba,oper,backupdba,dgdba,asmadmin,asmdba ${ORACLEUSER}

echo "设置oracle、grid用户资源使用限制"
cat <<EOF >>/etc/security/limits.conf
${GRIDUSER} soft nproc 2047
${GRIDUSER} hard nproc 16384
${GRIDUSER} soft nofile 1024
${GRIDUSER} hard nofile 65536
${GRIDUSER} soft stack 10240   
${GRIDUSER} hard stack 32768   
${ORACLEUSER} soft nproc 2047
${ORACLEUSER} hard nproc 16384
${ORACLEUSER} soft nofile 1024
${ORACLEUSER} hard nofile 65536
${ORACLEUSER} soft stack 10240   
${ORACLEUSER} hard stack 32768   
EOF
cat <<"EOF" >>/etc/profile.d/oracle.sh
if [ $USER = "${ORACLEUSER}" ] ||[ $USER = "${GRIDUSER}" ]; then
   if [ $SHELL = "/bin/ksh" ]; then
      ulimit -p 16384
      ulimit -n 65536
   else
       ulimit -u 16384 -n 65536
   fi
fi
EOF

echo "使用udev配置asm磁盘路径和权限"
volumestr="${outputs.multi.asm1.volumeCode}"
volumestr=${volumestr#[}
volumestr=${volumestr%]}
volumearr=(${volumestr//,/ })

for volume in ${volumearr[@]}; do
  #获取磁盘volume对应的序列号，后8位位序列号
  serial=${volume:4}
  #kvm平台序列号为大写，vmware平台序列号为小写，所以两个都写，不会同时起作用
  lserial=$(echo $serial | tr '[A-Z]' '[a-z]')
  cat <<EOF >>/etc/udev/rules.d/99-oracle-asmdevices.rules
    SUBSYSTEM=="block",ENV{ID_SERIAL}=="?*${serial}",NAME="asm-${volume}", OWNER="grid",GROUP="asmadmin", MODE="0660"
    SUBSYSTEM=="block",ENV{ID_SERIAL}=="?*${lserial}",NAME="asm-${volume}", OWNER="grid",GROUP="asmadmin", MODE="0660"
EOF
done

devices=$(printf ",/dev/asm-%s" "${volumearr[@]}")
devices=${devices:1}
export devices 
# 重新加载udev规则，触发生成asm磁盘盘符
udevadm control --reload-rules && udevadm trigger


echo "创建文件目录结构"
mkdir -p ${ORACLEPATH}/oracle/oraInventory
mkdir -p ${ORACLEPATH}/oracle/oracle
mkdir -p ${ORACLEPATH}/oracle/grid
mkdir -p ${ORACLEPATH}/oracle/oracle/product/12c/db_1/
mkdir -p ${ORACLEPATH}/oracle/grid/product/12c/grid/
mkdir -p ${ORACLEPATH}/install

chown -R ${GRIDUSER}:oinstall ${ORACLEPATH}
chown -R ${GRIDUSER}:oinstall ${ORACLEPATH}/oracle/oraInventory
chown -R ${ORACLEUSER}:oinstall ${ORACLEPATH}/oracle/oracle
chown -R ${GRIDUSER}:oinstall ${ORACLEPATH}/oracle/grid
chown -R ${ORACLEUSER}:oinstall ${ORACLEPATH}/oracle/oracle/product/12c/db_1/
chown -R ${GRIDUSER}:oinstall ${ORACLEPATH}/oracle/grid/product/12c/grid/
chmod 775 ${ORACLEPATH} -R


echo "下载oracle安装文件"
if [[ '${ORACLE_VERSION}' == '12.1.0.2' ]]; then
  wget -q ${INSTALLER_S3_BUCKET}/linuxamd64_12102_database_1of2.zip -O ${ORACLEPATH}/install/linuxamd64_12102_database_1of2.zip 
  wget -q ${INSTALLER_S3_BUCKET}/linuxamd64_12102_database_2of2.zip  -O ${ORACLEPATH}/install/linuxamd64_12102_database_2of2.zip 
  wget -q ${INSTALLER_S3_BUCKET}/linuxamd64_12102_grid_1of2.zip  -O ${ORACLEPATH}/install/linuxamd64_12102_grid_1of2.zip 
  wget -q ${INSTALLER_S3_BUCKET}/linuxamd64_12102_grid_2of2.zip  -O ${ORACLEPATH}/install/linuxamd64_12102_grid_2of2.zip
  wget -q ${INSTALLER_S3_BUCKET}/p6880880_122010_Linux-x86-64.zip  -O ${ORACLEPATH}/install/p6880880_122010_Linux-x86-64.zip
  wget -q ${INSTALLER_S3_BUCKET}/p28349951_121020_Linux-x86-64.zip  -O ${ORACLEPATH}/install/p28349951_121020_Linux-x86-64.zip
  wget -q ${INSTALLER_S3_BUCKET}/p28440711_121020_Linux-x86-64.zip  -O ${ORACLEPATH}/install/p28440711_121020_Linux-x86-64.zip
  if  [[ ! -f ${ORACLEPATH}/install/linuxamd64_12102_database_1of2.zip ]] || [[ ! -f ${ORACLEPATH}/install/linuxamd64_12102_database_2of2.zip ]] ; then 
    echo "无法下载database安装文件"
    exit 1
  fi
  if  [[ ! -f ${ORACLEPATH}/install/linuxamd64_12102_grid_1of2.zip ]] || [[ ! -f ${ORACLEPATH}/install/linuxamd64_12102_grid_2of2.zip ]] ; then 
    echo "无法下载grid安装文件"
    exit 1
  fi
fi
if [[ '${ORACLE_VERSION}' == '12.2.0.1' ]]; then
  wget -q ${INSTALLER_S3_BUCKET}/linuxx64_12201_database.zip -O ${ORACLEPATH}/install/linuxx64_12201_database.zip
  wget -q ${INSTALLER_S3_BUCKET}/linuxx64_12201_grid_home.zip -O ${ORACLEPATH}/install/linuxx64_12201_grid_home.zip
  wget -q ${INSTALLER_S3_BUCKET}/p6880880_122010_Linux-x86-64.zip -O ${ORACLEPATH}/install/p6880880_122010_Linux-x86-64.zip
  wget -q ${INSTALLER_S3_BUCKET}/p27468969_122010_Linux-x86-64.zip -O ${ORACLEPATH}/install/p27468969_122010_Linux-x86-64.zip
  wget -q ${INSTALLER_S3_BUCKET}/p27475613_122010_Linux-x86-64.zip -O ${ORACLEPATH}/install/p27475613_122010_Linux-x86-64.zip
  if  [[ ! -f ${ORACLEPATH}/install/linuxx64_12201_database.zip ]] || [[ ! -f ${ORACLEPATH}/install/linuxx64_12201_grid_home.zip ]] ; then 
    echo "无法下载安装文件"
    exit 1
  fi
fi

echo "下载oracle补丁文件"

chown -R ${GRIDUSER}:oinstall ${ORACLEPATH}/install

echo "解压环境"
if [[ '${ORACLE_VERSION}' == '12.1.0.2' ]]; then
  su -c 'cd ${ORACLEPATH}/install && unzip -q linuxamd64_12102_database_1of2.zip'   - ${ORACLEUSER}
  su -c 'cd ${ORACLEPATH}/install && unzip -q linuxamd64_12102_database_2of2.zip'   - ${ORACLEUSER}
  su -c 'cd ${ORACLEPATH}/install && unzip -q linuxamd64_12102_grid_1of2.zip'   - ${GRIDUSER}
  su -c 'cd ${ORACLEPATH}/install && unzip -q linuxamd64_12102_grid_2of2.zip'   - ${GRIDUSER}
fi
if [[ '${ORACLE_VERSION}' == '12.2.0.1' ]]; then
    su -c 'cd ${ORACLEPATH}/install && unzip -q linuxx64_12201_grid_home.zip -d ${ORACLEPATH}/oracle/grid/product/12c/grid/'   - ${GRIDUSER}
    su -c 'cd ${ORACLEPATH}/install && unzip -q linuxx64_12201_database.zip'   - ${ORACLEUSER}
fi


echo "配置grid用户环境变量"
su -c 'cat <<"EOF" >>/home/${GRIDUSER}/.bash_profile
export ORACLE_SID=+ASM
export ORACLE_BASE=${ORACLEPATH}/oracle/grid
export ORACLE_HOME=${ORACLEPATH}/oracle/grid/product/12c/grid/
export PATH=$ORACLE_HOME/bin:$ORACLE_HOME/OPatch:$ORACLE_HOME/jdk/bin:$PATH
EOF'  - ${GRIDUSER}



echo "生成grid的response文件"
if [[ '${ORACLE_VERSION}' == '12.1.0.2' ]]; then
cat <<EOF >${ORACLEPATH}/install/grid.rsp
oracle.install.responseFileVersion=/oracle/install/rspfmt_crsinstall_response_schema_v12.1.0 
INVENTORY_LOCATION=${ORACLEPATH}/oracle/oraInventory  
oracle.install.option=HA_CONFIG  
ORACLE_BASE=${ORACLEPATH}/oracle/grid
ORACLE_HOME=${ORACLEPATH}/oracle/grid/product/12c/grid
oracle.install.asm.OSDBA=asmdba  
oracle.install.asm.OSOPER=asmoper  
oracle.install.asm.OSASM=asmadmin  
oracle.install.crs.config.ClusterType=STANDARD
oracle.install.crs.config.autoConfigureClusterNodeVIP=false 
oracle.install.asm.SYSASMPassword=${ORACLEPASSWD}  
oracle.install.asm.diskGroup.name=DATA  
oracle.install.asm.diskGroup.redundancy=EXTERNAL  
oracle.install.asm.diskGroup.AUSize=1  
oracle.install.asm.diskGroup.disks=$devices  
oracle.install.asm.diskGroup.diskDiscoveryString=/dev/asm*  
oracle.install.asm.monitorPassword=${ORACLEPASSWD}  
EOF
cat <<EOF >${ORACLEPATH}/install/gridpass.rsp
oracle.assistants.asm|S_ASMPASSWORD=${ORACLEPASSWD}  
oracle.assistants.asm|S_ASMMONITORPASSWORD=${ORACLEPASSWD}  
EOF
chown ${GRIDUSER}:oinstall ${ORACLEPATH}/install/grid.rsp
chown ${GRIDUSER}:oinstall ${ORACLEPATH}/install/gridpass.rsp
fi

if [[ '${ORACLE_VERSION}' == '12.2.0.1' ]]; then
cat <<EOF >${ORACLEPATH}/install/grid.rsp
oracle.install.responseFileVersion=/oracle/install/rspfmt_crsinstall_response_schema_v12.2.0 
INVENTORY_LOCATION=${ORACLEPATH}/oracle/oraInventory  
oracle.install.option=HA_CONFIG  
ORACLE_BASE=${ORACLEPATH}/oracle/grid
ORACLE_HOME=${ORACLEPATH}/oracle/grid/product/12c/grid
oracle.install.asm.OSDBA=asmdba  
oracle.install.asm.OSOPER=asmoper  
oracle.install.asm.OSASM=asmadmin  
oracle.install.asm.storageOption=ASM  
oracle.install.asm.SYSASMPassword=${ORACLEPASSWD}  
oracle.install.asm.diskGroup.name=DATA  
oracle.install.asm.diskGroup.redundancy=EXTERNAL  
oracle.install.asm.diskGroup.AUSize=1  
oracle.install.asm.diskGroup.disks=$devices  
oracle.install.asm.diskGroup.diskDiscoveryString=/dev/asm*  
oracle.install.asm.monitorPassword=${ORACLEPASSWD}  
EOF
chown ${GRIDUSER}:oinstall ${ORACLEPATH}/install/grid.rsp
fi

echo "开始安装grid"
if [[ '${ORACLE_VERSION}' == '12.1.0.2' ]]; then
    su -c '${ORACLEPATH}/install/grid/runInstaller -silent -ignoreSysPrereqs  -responseFile ${ORACLEPATH}/install/grid.rsp -waitforcompletion'   - ${GRIDUSER}
    ${ORACLEPATH}/oracle/oraInventory/orainstRoot.sh
    ${ORACLEPATH}/oracle/grid/product/12c/grid/root.sh 
    su -c '${ORACLEPATH}/oracle/grid/product/12c/grid/cfgtoollogs/configToolAllCommands RESPONSE_FILE=${ORACLEPATH}/install/gridpass.rsp'   - ${GRIDUSER}
fi
if [[ '${ORACLE_VERSION}' == '12.2.0.1' ]]; then
    su -c '${ORACLEPATH}/oracle/grid/product/12c/grid/gridSetup.sh  -silent -skipPrereqs -ignorePrereqFailure  -responseFile ${ORACLEPATH}/install/grid.rsp -waitforcompletion'   - ${GRIDUSER}
    echo "安装grid后执行root脚本"
    ${ORACLEPATH}/oracle/oraInventory/orainstRoot.sh
    ${ORACLEPATH}/oracle/grid/product/12c/grid/root.sh
    su -c '${ORACLEPATH}/oracle/grid/product/12c/grid/gridSetup.sh -executeConfigTools -responseFile ${ORACLEPATH}/install/grid.rsp -silent -waitforcompletion'   - ${GRIDUSER}
fi

echo "查看磁盘"
su -c "asmcmd lsdsk -p -G DATA"  - ${GRIDUSER}

echo "配置oracle用户环境变量"
su -c 'cat <<"EOF" >>/home/${ORACLEUSER}/.bash_profile
export ORACLE_BASE=${ORACLEPATH}/oracle/oracle
export ORACLE_HOME=${ORACLEPATH}/oracle/oracle/product/12c/db_1/
export ORACLE_SID=${ORACLESID}
export PATH=.:$ORACLE_HOME/bin:$ORACLE_HOME/OPatch:$ORACLE_HOME/jdk/bin:$PATH
export LD_LIBRARY_PATH=${ORACLEPATH}/oracle/oracle/product/12c/db_1/lib:/lib:/usr/lib
export CLASSPATH=${ORACLEPATH}/oracle/oracle/product/12c/db_1/jlib:${ORACLEPATH}/oracle/oracle/product/12c/db_1/rdbms/jlib
EOF'  - ${ORACLEUSER}

echo "生成oracle的response文件"

if [[ '${ORACLE_VERSION}' == '12.1.0.2' ]]; then
su -c 'cat <<"EOF" >${ORACLEPATH}/install/database.rsp
oracle.install.responseFileVersion=/oracle/install/rspfmt_dbinstall_response_schema_v12.1.0
oracle.install.option=INSTALL_DB_SWONLY             
UNIX_GROUP_NAME=oinstall                            
INVENTORY_LOCATION=${ORACLEPATH}/oracle/oraInventory                      
SELECTED_LANGUAGES=en                               
ORACLE_HOME=${ORACLEPATH}/oracle/oracle/product/12c/db_1                            
ORACLE_BASE=${ORACLEPATH}/oracle/oracle                             
oracle.install.db.InstallEdition=EE                      
oracle.install.db.DBA_GROUP=dba                   
oracle.install.db.OPER_GROUP=oper                  
oracle.install.db.BACKUPDBA_GROUP=backupdba             
oracle.install.db.DGDBA_GROUP=dgdba                 
oracle.install.db.KMDBA_GROUP=dba                             
SECURITY_UPDATES_VIA_MYORACLESUPPORT=false          
DECLINE_SECURITY_UPDATES=true
EOF'   - ${ORACLEUSER}
fi
if [[ '${ORACLE_VERSION}' == '12.2.0.1' ]]; then
su -c 'cat <<"EOF" >${ORACLEPATH}/install/database.rsp
oracle.install.responseFileVersion=/oracle/install/rspfmt_dbinstall_response_schema_v12.2.0
oracle.install.option=INSTALL_DB_SWONLY             
UNIX_GROUP_NAME=oinstall                            
INVENTORY_LOCATION=${ORACLEPATH}/oracle/oraInventory                      
SELECTED_LANGUAGES=en                               
ORACLE_HOME=${ORACLEPATH}/oracle/oracle/product/12c/db_1                            
ORACLE_BASE=${ORACLEPATH}/oracle/oracle                             
oracle.install.db.InstallEdition=EE                           
oracle.install.db.OSDBA_GROUP=dba                   
oracle.install.db.OSOPER_GROUP=oper                  
oracle.install.db.OSBACKUPDBA_GROUP=backupdba             
oracle.install.db.OSDGDBA_GROUP=dgdba                 
oracle.install.db.OSKMDBA_GROUP=dba                 
oracle.install.db.OSRACDBA_GROUP=dba                
SECURITY_UPDATES_VIA_MYORACLESUPPORT=false          
DECLINE_SECURITY_UPDATES=true
EOF'   - ${ORACLEUSER}
fi


echo "安装oracle"
if [[ '${ORACLE_VERSION}' == '12.1.0.2' ]]; then
   su -c '${ORACLEPATH}/install/database/runInstaller -silent -ignoreSysPrereqs -ignorePrereq -responsefile ${ORACLEPATH}/install/database.rsp -waitforcompletion'   - ${ORACLEUSER}
fi
if [[ '${ORACLE_VERSION}' == '12.2.0.1' ]]; then
   su -c '${ORACLEPATH}/install/database/runInstaller -silent -ignoreSysPrereqs -ignorePrereq -ignorePrereqFailure -responsefile ${ORACLEPATH}/install/database.rsp -waitforcompletion'   - ${ORACLEUSER}
fi
echo "root执行安装"
${ORACLEPATH}/oracle/oracle/product/12c/db_1/root.sh

if [[ '${ORACLE_VERSION}' == '12.1.0.2' ]] && [[ -f ${ORACLEPATH}/install/p6880880_122010_Linux-x86-64.zip ]]; then
  echo "更新grid OPatch和数据库补丁"
  su -c 'unzip -o -q ${ORACLEPATH}/install/p6880880_122010_Linux-x86-64.zip -d ${ORACLEPATH}/oracle/grid/product/12c/grid/' - ${GRIDUSER}
  su -c 'unzip -o -q ${ORACLEPATH}/install/p28349951_121020_Linux-x86-64.zip -d ${ORACLEPATH}/install/' - ${GRIDUSER}
  su -c 'unzip -o -q ${ORACLEPATH}/install/p28440711_121020_Linux-x86-64.zip -d ${ORACLEPATH}/install/' - ${GRIDUSER}
  ${ORACLEPATH}/oracle/grid/product/12c/grid/OPatch/opatchauto apply ${ORACLEPATH}/install/28349951/
  ${ORACLEPATH}/oracle/grid/product/12c/grid/OPatch/opatchauto apply ${ORACLEPATH}/install/28440711/
fi

echo "更新补丁"
if [[ '${ORACLE_VERSION}' == '12.2.0.1' ]] && [[ -f ${ORACLEPATH}/install/p6880880_122010_Linux-x86-64.zip ]]; then
  su -c 'unzip -o -q ${ORACLEPATH}/install/p6880880_122010_Linux-x86-64.zip -d ${ORACLEPATH}/oracle/grid/product/12c/grid/' - ${GRIDUSER}
  su -c 'unzip -o -q ${ORACLEPATH}/install/p27468969_122010_Linux-x86-64.zip -d ${ORACLEPATH}/install/' - ${GRIDUSER}
  su -c 'unzip -o -q ${ORACLEPATH}/install/p27475613_122010_Linux-x86-64.zip -d ${ORACLEPATH}/install/' - ${GRIDUSER}
  ${ORACLEPATH}/oracle/grid/product/12c/grid/OPatch/opatchauto apply ${ORACLEPATH}/install/27468969/
  ${ORACLEPATH}/oracle/grid/product/12c/grid/OPatch/opatchauto apply ${ORACLEPATH}/install/27475613/
fi


echo "创建数据库并启动归档"
sleep 60 #补丁完需要等一下asm才启动
if [[ '${ORACLE_VERSION}' == '12.2.0.1' ]] ; then
# 12.2在使用dbca创建数据库时可以同步启用archivelog，默认归档路径在闪回恢复区（Recovery Area Destination）
su -c 'dbca -silent \
-createDatabase \
-templateName General_Purpose.dbc \
-gdbName ${ORACLESID} \
-sid ${ORACLESID} \
-SysPassword ${ORACLEPASSWD}   \
-SystemPassword ${ORACLEPASSWD}   \
-emConfiguration LOCAL \
-storageType ASM \
-diskGroupName DATA -recoveryGroupName DATA \
-recoveryAreaDestination +DATA \
-datafileDestination +DATA \
-characterSet ${ORACLE_CHARACTER} \
-memoryPercentage 50 \
-enableArchive true \
-redoLogFileSize 128 \
-recoveryAreaSize 10240 ' - ${ORACLEUSER}
fi

if [[ '${ORACLE_VERSION}' == '12.1.0.2' ]] ; then
# 12.1在使用dbca创建数据库时不可以同步启用archivelog，所以步骤分为先创建数据库后配置归档
su -c 'dbca -silent \
-createDatabase \
-templateName General_Purpose.dbc \
-gdbName ${ORACLESID} \
-sid ${ORACLESID} \
-SysPassword ${ORACLEPASSWD}   \
-SystemPassword ${ORACLEPASSWD}   \
-emConfiguration LOCAL \
-storageType ASM \
-diskGroupName DATA -recoveryGroupName DATA \
-datafileDestination +DATA \
-characterSet ${ORACLE_CHARACTER} \
-memoryPercentage 50 \
-redoLogFileSize 128' - ${ORACLEUSER}


# 配置归档日志文件路径（+DATA）以及大小100G
su -c 'sqlplus "/as sysdba" <<EOF
alter system set db_recovery_file_dest_size = 100G scope=both;
quit;
EOF'  - ${ORACLEUSER}
# 关闭Oracle数据库
echo "shuting down oracle befor archiving redo logs"
su -c 'srvctl stop database -db ${ORACLESID} -stopoption IMMEDIATE'  - ${ORACLEUSER}
# 启动归档文件
echo "启动归档日志"

su -c 'srvctl start database -db ${ORACLESID} -startoption MOUNT'  - ${ORACLEUSER}

su -c 'sqlplus "/as sysdba" <<EOF
alter database archivelog;
alter database open;
alter system archive log current;
archive log list;
quit;
EOF'  - ${ORACLEUSER}
fi

echo "启动emctl，默认端口为5500"
su -c 'sqlplus "/as sysdba" <<EOF
exec dbms_xdb_config.sethttpsport(5500);
quit;
EOF'  - ${ORACLEUSER}
echo "可以访问 https://${outputs.oracle_primary.privateIp}:5500/em 进行管理"

echo "oracle 部署完成"
su -c 'srvctl config database -d  ${ORACLESID}' - ${ORACLEUSER}

echo "数据库管理请使用srvctl start database -db ${ORACLESID}/srvctl stop database -db ${ORACLESID}"