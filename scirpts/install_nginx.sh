#! /bin/sh
#######################
# NGINXURL：s3路径，例如http://169.254.169.254:8683/bingoinstall/nginx-1.12.2.zip
#######################
echo "下载nginx软件包"
wget -q ${NGINXURL} -O nginx-1.12.2.zip
echo "解压nginx软件包"
unzip -q nginx-1.12.2.zip
echo "安装nginx"
yum install nginx-1.12.2/*.rpm -y 
echo "安装完成"