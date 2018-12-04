# 制作单机模式的MongoDB应用
&emsp;&emsp;本教程是面向熟悉使用SIP4.1的管理人员，需要具备看懂简单Shell脚本的能力，对SIP4.1自动化部署流程有一定的了解。若您对SIP4.1不了解，建议先学习“SIP4.1使用手册”。  
> SIP4.1使用手册（sip_user_guide_v4.1.0.20180930）：http://  

### 一、安装包准备和上传
1、下载MongoDB安装程序和脚本。  
> MongoDB安装程序(mongodb.tar.gz)：  
> http://  
> MongoDB安装脚本(install_mongodb_single.sh)：  
> https://github.com/bcdelivery/autodeploy/blob/master/scirpts/install_mongodb_single.sh  

2、将下载好的MongoDB安装程序(mongodb.tar.gz)上传到s3，设置所有人权限可读，记录url。  

![](../asset/mongodb_single/209f2f8872e481886edf1d793485242b.png)

3、将MongoDB安装脚本(install_mongodb_single.sh)新增进SIP。  

![](../asset/mongodb_single/dd34a90b3151d072e241c5cd7ba95f77.png)

![](../asset/mongodb_single/76a1bb5b56beedf859ba4c10a9f4e959.png)

* 新增如下变量：  
```
MONGODHOME=${MONGODHOME}
MONGODBPATH=${MONGODBPATH}
MONGODLOGDIR=${MONGODLOGDIR}
MONGODB_PROGRAM=${MONGODB_PROGRAM}
MONGODB_MANAGE=${MONGODB_MANAGE}
MONGODB_MANAGE7=${MONGODB_MANAGE7}
MONGODB_TAR_DIR=${MONGODB_TAR_DIR}
```
* 显示名称根据需要填写，变量类型“text”，变量内容从上往下依次为：  
```
/usr/local/mongodb
/data/db
/var/log/mongo
/tmp/mongodb/mongodb-linux-x86_64-3.4.18.tgz
/tmp/mongodb/mongodb_manage.sh
/tmp/mongodb/mongodb_manage_rc7.sh
/tmp/mongo
```

![](../asset/mongodb_single/033e0c5b058372eb1a6d464c9d061b0d.png)

* 将MongoDB安装脚本(install_mongodb_single.sh)的脚本内容全选，复制粘贴进代码框后，提交：  

![](../asset/mongodb_single/e10528e13dd661d95be585582f8b39d4.png)

### 二、设计方案
1、在窗口的左边有许多控件，那是“控件菜单”，从左拖拽如下图所示的控件到编辑区，依次为：开始事件、安全组、实例、存储、通用指令、自定义指令、通用指令、结束事件：  

![](../asset/mongodb_single/e86b1aa274eecbc9d99191d2c40d47f3.png)

![](../asset/mongodb_single/78748c723dfd8d7f9b9a5ce934a7d1bf.png)

2、接着在编辑区内点击“第一个控件”，当看到控件的“右上角有个箭头”的时候，点击按住不放，拖拽到其右边的控件上，松开鼠标，即可看到两个控件间有“谁指向谁”的箭头，从左往右依次做箭头指向操作：  

![](../asset/mongodb_single/f52cb6949462b8d24441430c674f1159.png)

3、点击“开始事件”，根据需要填写控件的相关信息：  
注意：红色方框内的内容必填，名称建议用英文表示。  

![](../asset/mongodb_single/c96ca052cafeb46c7d5d795954eb4f46.png)

4、点击“安全组”，根据需要填写控件的相关信息：  
注意：红色方框内的内容必填，编号、名称都用英文表示。  

![](../asset/mongodb_single/c7beb6ed880d74baa6f27d999a423f0b.png)

5、点击“端口信息”，根据需要开放相应协议的端口号：  

![](../asset/mongodb_single/1618359e22bc1d28d197afbb284cec81.png)

6、点击“实例”，根据需要填写控件的相关信息：  
注意：红色方框内的内容必填，编号、名称、实例名称都用英文表示。  

![](../asset/mongodb_single/84ad5716c1222402caaa33a0dc03fb2e.png)

7、点击“存储”，根据需要填写控件的相关信息：  
注意：红色方框内的内容必填，编号、名称都用英文表示，**实例ID**和**实例编号**中的填写格式是：  
> 实例ID：${outputs.<font color=#7FFF00>single</font>.instanceId}  
> 实例编号：${outputs.<font color=#7FFF00>single</font>.instanceCode} 
绿色标记的是**“实例”控件**中的**“编号”**，必须一致。  

![](../asset/mongodb_single/e5aeadde2e3fda687139a8dd237f2ce6.png)

8、点击“通用指令”，根据需要填写控件的相关信息：
注意：红色方框内的内容必填，编号、名称都用英文表示，**实例ID**和**实例编号**中的填写格式是：  
> 实例ID：${outputs.<font color=#7FFF00>single</font>.instanceId}  
> 实例编号：${outputs.<font color=#7FFF00>single</font>.instanceCode}
绿色标记的是**“实例”控件**中的**“编号”**，必须一致。  

![](../asset/mongodb_single/4a59fd1fa0e9fdd81ae16ee5f59570eb.png)

9、点击“脚本文件”，选择格式化挂载存储卷的脚本**linux_volume_attach**：  

![](../asset/mongodb_single/9c92234d2f8320eff8d58afb0fe6a5a0.png)

> linux_volume_attach脚本相关变量备注：  

![](../asset/mongodb_single/06b5c1e37a073dbbebba8e754b7ceafe.png)

10、点击“自定义指令”，根据需要填写控件的相关信息：  
注意：红色方框内的内容必填，编号、名称都用英文表示，**实例ID**中的填写格式是：  
> 实例ID：${outputs.<font color=#7FFF00>single</font>.instanceId}  
绿色标记的是“实例”控件中的**“实例ID”**，必须一致。  

![](../asset/mongodb_single/7758b4e05d9f63758e8b4e4d34403077.png)

11、点击“指令内容”，输入：  
```
#!/bin/bash
wget http://10.201.83.1:81/data/mongodb.tar.gz -O /tmp/mongodb.tar.gz
tar -zxvf /tmp/mongodb.tar.gz -C /tmp
echo "tar done" && exit 0
```
> 注意：若前面我们新增的"MongoDB安装脚本(install_mongodb_single.sh)"新增的变量内容有改变的话，如变量指定的内容不是/tmp目录，则上述指令内容中，tar需根据实际变动目录解压安装程到相应目录。  
```
MONGODB_PROGRAM=\${MONGODB_PROGRAM}
MONGODB_MANAGE=\${MONGODB_MANAGE}
MONGODB_MANAGE7=\${MONGODB_MANAGE7}
```

12、点击“通用指令”，根据需要填写控件的相关信息：  
注意：红色方框内的内容必填，编号、名称都用英文表示，**实例ID**中的填写格式是：  
> 实例ID：${outputs.<font color=#7FFF00>single</font>.instanceId}  
绿色标记的是“实例”控件中的**“实例ID”**，必须一致。  

13、点击“脚本文件”，选择前面我们新创建的mongosb_single脚本：

![](../asset/mongodb_single/9872642e86c72ed4a5221f85671a2142.png)

![](../asset/mongodb_single/92bba2be1b8d4280480cc374711f7f84.png)

14、点击“结束事件”，根据需要填写控件的相关信息：  
注意：红色方框内的内容必填，名称建议用英文表示。  

![](../asset/mongodb_single/087fc864d1583a8e1001f48e65de7d3e.png)

15、在控件区的顶部点击“保存”图标，保存编辑好的部署方案：  

![](../asset/mongodb_single/84162f4fc57cc928ba117bcf7cd4e93e.png)

### 三、参数模板
1、点击“新建模板”：  

![](../asset/mongodb_single/595e51d3dc734ee87ea1f124edead231.png)

2、填写脚相关信息，选择模板为“云主机+存储卷”，点击“生成”：  

![](../asset/mongodb_single/a86a1aa2c74f0fa2493fdf7ace3a65ea.png)

3、在“参数列表”中，找到“imageId”，点击最右侧的“编辑”按钮：

![](../asset/mongodb_single/c05455a782143640960e3bdbd314d292.png)

4、修改镜像的默认值为当前云平台“可支持自动化部署”的镜像ID：  
> tip：这里也能开启“是为允许用户修改”为“TRUE”，这样用户在部署的时候就可以指定镜像。  

![](../asset/mongodb_single/88ed2d19ffa8fb2abc0d4dc7cb4538bf.png)

5、保存对imageID的修改，点击“JSON”，将JSON编辑区拉到最下面：  

![](../asset/mongodb_single/b201acb6d0e0088b3eb356cbbcf3d722.png)

6、在原有的JSON下，新增关于mongodb_single的变量的JSON：  
```
{
"DefaultValue": "/tmp/mongodb/mongodb-linux-x86_64-3.4.18.tgz",
"Type": "String",
"DisplayName": "安装程序",
"AllowedCustomization": true,
"NameSpace": "install",
"Key": "MONGODB_PROGRAM"
},
{
"DefaultValue": "/usr/local/mongodb",
"Type": "String",
"DisplayName": "程序家目录",
"AllowedCustomization": true,
"NameSpace": "install",
"Key": "MONGODHOME"
},
{
"DefaultValue": "/var/log/mongo",
"Type": "String",
"DisplayName": "日志目录",
"AllowedCustomization": true,
"NameSpace": "install",
"Key": "MONGODLOGDIR"
},
{
"DefaultValue": "/tmp/mongo",
"Type": "String",
"DisplayName": "临时目录",
"AllowedCustomization": true,
"NameSpace": "install",
"Key": "MONGODB_TAR_DIR"
},
{
"DefaultValue": "/tmp/mongodb/mongodb_manage.sh",
"Type": "String",
"DisplayName": "rhel6/centos6管理程序",
"AllowedCustomization": true,
"NameSpace": "install",
"Key": "MONGODB_MANAGE"
},
{
"DefaultValue": "/data/db",
"Type": "String",
"DisplayName": "数据库目录",
"AllowedCustomization": true,
"NameSpace": "install",
"Key": "MONGODBPATH"
},
{
"DefaultValue": "/tmp/mongodb/mongodb_manage_rc7.sh",
"Type": "String",
"DisplayName": "rhel7/centos7管理程序",
"AllowedCustomization": true,
"NameSpace": "install",
"Key": "MONGODB_MANAGE7"
}
```
注意：该json中相关变量的值需要与mongodb_single脚本中变量内容一致。  
> 重要：注意json的格式！  

![](../asset/mongodb_single/53eb1d62cbd64a1a40d13a24221b35e4.png)

![](../asset/mongodb_single/fd6f405f85edf2b279b7bf85fef53e8d.png)

7、最后保存该参数模板：

![](../asset/mongodb_single/8ee3a99809a93b185bca6f5f43b82588.png)

### 四、测试部署结果
1、测试MongoDB的单机模式连接：  

![](../asset/mongodb_single/2d4879ede36561878aa7683c414efe19.png)

2、结束  

