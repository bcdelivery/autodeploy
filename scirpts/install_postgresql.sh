#! /bin/sh
#######################
# VOLUMEID:存储卷volume id，大小写无关
# FSTYPE：格式化磁盘文件系统类型，支持ext3、ext4、btrfs
# MOUNTPOINT: 挂载点
# NEEDREBOOT: 是否需要重启
#######################

#安装
yum -y install https://download.postgresql.org/pub/repos/yum/11/redhat/rhel-7-x86_64/pgdg-centos11-11-2.noarch.rpm
yum -y install postgresql11
yum -y install postgresql11-server

# 设置数据文件目录
chown postgres /data/postgresql/data
initdb -D /data/postgresql/data

/usr/pgsql-11/bin/postgresql-11-setup initdb
systemctl enable postgresql-11
systemctl start postgresql-11


#设置密码
#su - postgres
-bash-4.2$ psql -U postgres
psql (11.0)
Type "help" for help.
 
postgres=# ALTER USER postgres with encrypted password 'postgres';
ALTER ROLE
postgres=# \q



# 开通防火墙
firewall-cmd --zone=public --add-port=5432/tcp --permanent
firewall-cmd --reload
firewall-cmd --list-ports

#开通远程访问
vim /var/lib/pgsql/11/data/postgresql.conf
listen_addresses = '*'

vim /var/lib/pgsql/11/data/pg_hba.conf
# 增加下面允许指定地址空间访问
host    all             all             0.0.0.0/0               md5

#重启服务
systemctl restart postgresql-11