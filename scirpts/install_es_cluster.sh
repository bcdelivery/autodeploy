# 设置主机名映射
# 安装jdk8
# 安装es软件包
# 修改 /etc/elasticsearch/elasticsearch.yml
path:
  logs: /var/log/elasticsearch
  data:
    - /mnt/elasticsearch_1
    - /mnt/elasticsearch_2
    - /mnt/elasticsearch_3
# The name of the cluster. Must be the same for all nodes.
cluster.name: cluster1

# The name for the node. Using the node's hostname is a good choice.
node.name: es-node1

# Specify the private IP of the node.
network.host: 10.99.0.10

# Allow Elasticsearch to lock it's address space.
bootstrap.mlockall: true

# List the IPs of all the nodes here. Most cloud providers don't support
# multicast, so we have to explicitly identify nodes like this.
discovery.zen.ping.unicast.hosts: ["10.99.0.10", "10.99.0.11", "10.99.0.12"]

# In our case, we need a majority of 2 at all times to avoid "split brain".
discovery.zen.minimum_master_nodes: 2


cluster.name：Any name. Must be the same across all nodes.
node.name：Any name.
node.master：Whether or not this is a master node, meaning one that coordinates the activity of data nodes. In our example, we have 1 master and 2 data nodes. The master can also serve as a data node.
node.data：Indicates whether this node can store data.
node.ingest：Used to pre-process documents before they are indexed.
discovery.zen.hosts_provider：Use ec2 for node discovery.
discovery.zen.ping.unicast.hosts：List the IP address of all master and data nodes in the cluster. Enclose in commas.
network.host：The private IP address of this machine, i.e., the one shown by the ifconfig -a command. This is not the public address that you use to ssh into the machine from your laptop.


# 修改/etc/elasticsearch/jvm.options
-Xms2g 
-Xmx2g 
#The value should be 50% of available RAM, but not more than 31g (the JVM garbage collector slows down after this limit).
ES_HEAP_SIZE=4g
MAX_OPEN_FILES=131070

#  修改/usr/lib/systemd/system/elasticsearch.service
LimitMEMLOCK=infinity

# 修改sudo vim /etc/sysctl.conf
vm.max_map_count=262144
# sudo vim  /etc/security/limits.conf
 - nofile 65536

# 认证安装x-pack
bin/elasticsearch-plugin install x-pack
./setup-passwords interactive


编辑 elasticsearch/config/elasticsearch.yml

http.cors.enabled: true
http.cors.allow-origin: '*'
http.cors.allow-headers: Authorization,X-Requested-With,Content-Length,Content-Type



# 启动服务
sudo systemctl daemon-reload
sudo systemctl enable elasticsearch
sudo systemctl start elasticsearch

# 健康状态
curl -XGET http://172.31.46.15:9200/_cluster/health?pretty

# 节点状态
所有节点
curl -XGET 'localhost:9200/_nodes/stats?pretty'
特定节点
curl -XGET 'localhost:9200/_nodes/node-1/stats?pretty'
索引状态
curl -XGET 'localhost:9200/_nodes/stats/indices?pretty'


参考链接：
https://www.jianshu.com/p/f53da7e6469c