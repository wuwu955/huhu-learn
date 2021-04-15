## 软件安装笔记

### 1 docker 安装zk

```pwd

#拉取zk镜像
docker pull zookeeper:3.5
#创建容器
docker create --name zk -p 2181:2181 zookeeper:3.5
#启动容器
docker start zk

```

### 2  dubbo-admin 安装

```pwd
# https://github.com/apache/incubator-dubbo-ops
#clone 项目
git clone https://github.com/apache/incubator-dubbo-ops.git
#修改配置文件中注册地址
dubbo-admin-backend/src/main/resources/application.properties
#重新打包
mvn clean package
#启动
mvn --projects dubbo-admin-backend spring-boot:run
#访问
打开浏览器，进行访问:http://localhost:8080/#/

```

### 3 docker安装MySQL

```pwd
#镜像地址:https://hub.docker.com/_/percona/ #拉取镜像
docker pull percona:5.7.23
#创建容器
docker create --name percona -v /data/mysql-data:/var/lib/mysql -p 3306:3306 -e MYSQL_ROOT_PASSWORD=root percona:5.7.23
#参数解释:
--name: percona 指定是容器的名称
-v: /data/mysql-data:/var/lib/mysql 将主机目录/data/mysql-data挂载到容器 的/var/lib/mysql上
-p: 33306:3306 设置端口映射，主机端口是33306，容器内部端口3306
-e: MYSQL_ROOT_PASSWORD=root 设置容器参数，设置root用户的密码为root percona:5.7.23: 镜像名:版本
#启动容器
docker start percona

```

### 4 搭建nginx进行访问图片

```pwd
#nginx 配置
server{
listen 80;
#服务地址
server_name huhu.melon.com;
location /file/ {
#文件路径
  root /home/china/areas/;
  }
}
#host 配置

127.0.0.1 huhu.melon.com


```
### 5 docker 安装redis 
```pwd
#拉取镜像
docker pull redis:5.0.2
#创建容器
docker create --name redis-node01 -v /data/redis-data/node01:/data -p 6379:6379 redis:5.0.2 --cluster-enabled yes --cluster-config-file nodes-node-01.conf
docker create --name redis-node02 -v /data/redis-data/node02:/data -p 6380:6379
redis:5.0.2 --cluster-enabled yes --cluster-config-file nodes-node-02.conf
docker create --name redis-node03 -v /data/redis-data/node03:/data -p 6381:6379
redis:5.0.2 --cluster-enabled yes --cluster-config-file nodes-node-03.conf
#启动容器
docker start redis-node01 redis-node02 redis-node03
#开始组建集群 #进入redis-node01进行操作
docker exec -it redis-node01 /bin/bash
#组建集群 172.16.55.185是主机的ip地址
redis-cli --cluster create 172.16.55.185:6379 172.16.55.185:6380 172.16.55.185:6381
--cluster-replicas 0
#查看集群信息
/data# redis-cli
127.0.0.1:6379> CLUSTER NODES
46e5582cd2d96a506955cc08e7b08343037c91d9 172.16.55.185:6380@16380 master - 0
1543766975796 2 connected 5461-10922
b42d6ccc544094f1d8f35fa7a6d08b0962a6ac4a 172.16.55.185:6381@16381 master - 0
1543766974789 3 connected 10923-16383
4c60f45d1722f771831c64c66c141354f0e28d18 172.16.55.185:6379@16379 myself,master - 0
1543766974000 1 connected 0-5460

#这里要好好学一下 day7文档

```
### 6 docker安装mongodb

```pwd
#拉取镜像
docker pull mongo:4.0.3
#创建容器
docker create --name mongodb -p 27017:27017 -v /data/mongodb:/data/db mongo:4.0.3
#启动容器
docker start mongodb
#进入容器
docker exec -it mongodb /bin/bash
#使用MongoDB客户端进行操作 mongo
> show dbs #查询所有的数据库 admin 0.000GB
config 0.000GB
local 0.000GB

```
### 7 docker安装rocketMq

```pwd
#拉取镜像
docker pull foxiswho/rocketmq:server-4.3.2 docker pull foxiswho/rocketmq:broker-4.3.2
#创建nameserver容器
docker create -p 9876:9876 --name rmqserver \
-e "JAVA_OPT_EXT=-server -Xms128m -Xmx128m -Xmn128m" \ -e "JAVA_OPTS=-Duser.home=/opt" \
-v /haoke/rmq/rmqserver/logs:/opt/logs \
-v /haoke/rmq/rmqserver/store:/opt/store \ foxiswho/rocketmq:server-4.3.2
#创建broker容器
docker create -p 10911:10911 -p 10909:10909 --name rmqbroker \
-e "JAVA_OPTS=-Duser.home=/opt" \
-e "JAVA_OPT_EXT=-server -Xms128m -Xmx128m -Xmn128m" \
-v /haoke/rmq/rmqbroker/conf/broker.conf:/etc/rocketmq/broker.conf \ -v /haoke/rmq/rmqbroker/logs:/opt/logs \
-v /haoke/rmq/rmqbroker/store:/opt/store \ foxiswho/rocketmq:broker-4.3.2
#启动容器
docker start rmqserver rmqbroker
#停止删除容器
docker stop rmqbroker rmqserver docker rm rmqbroker rmqserver
安装 管理台https://github.com/apache/rocketmq-externals/tree/master/rocketmq-console
#拉取镜像
docker pull styletang/rocketmq-console-ng:1.0.0
#创建并启动容器
docker run -e "JAVA_OPTS=-Drocketmq.namesrv.addr=172.16.55.185:9876 - Dcom.rocketmq.sendMessageWithVIPChannel=false" -p 8082:8080 -t styletang/rocketmq- console-ng:1.0.0

```
### 8 docker安装rocketMq 2m2s（两主两从）
```pwd

#创建2个master
#nameserver1
docker create -p 9876:9876 --name rmqserver01 \
-e "JAVA_OPT_EXT=-server -Xms128m -Xmx128m -Xmn128m" \ -e "JAVA_OPTS=-Duser.home=/opt" \
-v /haoke/rmq/rmqserver01/logs:/opt/logs \
-v /haoke/rmq/rmqserver01/store:/opt/store \ foxiswho/rocketmq:server-4.3.2

#nameserver2
docker create -p 9877:9876 --name rmqserver02 \
-e "JAVA_OPT_EXT=-server -Xms128m -Xmx128m -Xmn128m" \
-e "JAVA_OPTS=-Duser.home=/opt"  \
-v /haoke/rmq/rmqserver02/logs:/opt/logs \
-v /haoke/rmq/rmqserver02/store:/opt/store \
foxiswho/rocketmq:server-4.3.2

#创建第1个master broker
#master broker01
docker create --net host --name rmqbroker01 \
-e "JAVA_OPTS=-Duser.home=/opt" \
-e "JAVA_OPT_EXT=-server -Xms128m -Xmx128m -Xmn128m" \
-v /haoke/rmq/rmqbroker01/conf/broker.conf:/etc/rocketmq/broker.conf \ -v /haoke/rmq/rmqbroker01/logs:/opt/logs \
-v /haoke/rmq/rmqbroker01/store:/opt/store \ foxiswho/rocketmq:broker-4.3.2

#配置
namesrvAddr=172.16.55.185:9876;172.16.55.185:9877
brokerClusterName=HaokeCluster
brokerName=broker01
brokerId=0
deleteWhen=04
fileReservedTime=48
brokerRole=SYNC_MASTER
flushDiskType=ASYNC_FLUSH
brokerIP1=172.16.55.185
brokerIp2=172.16.55.185
listenPort=10911

#创建第2个master broker
#master broker02
docker create --net host --name rmqbroker02 \
-e "JAVA_OPTS=-Duser.home=/opt" \
-e "JAVA_OPT_EXT=-server -Xms128m -Xmx128m -Xmn128m" \
-v /haoke/rmq/rmqbroker02/conf/broker.conf:/etc/rocketmq/broker.conf \ -v /haoke/rmq/rmqbroker02/logs:/opt/logs \
-v /haoke/rmq/rmqbroker02/store:/opt/store \ foxiswho/rocketmq:broker-4.3.2

#master broker02
namesrvAddr=172.16.55.185:9876;172.16.55.185:9877
brokerClusterName=HaokeCluster
brokerName=broker02
brokerId=0
deleteWhen=04
fileReservedTime=48
brokerRole=SYNC_MASTER
flushDiskType=ASYNC_FLUSH
brokerIP1=172.16.55.185
brokerIp2=172.16.55.185
listenPort=10811

#创建第1个slave broker
#slave broker01
docker create --net host --name rmqbroker03 \
-e "JAVA_OPTS=-Duser.home=/opt" \
-e "JAVA_OPT_EXT=-server -Xms128m -Xmx128m -Xmn128m" \
-v /haoke/rmq/rmqbroker03/conf/broker.conf:/etc/rocketmq/broker.conf \ -v /haoke/rmq/rmqbroker03/logs:/opt/logs \
-v /haoke/rmq/rmqbroker03/store:/opt/store \ foxiswho/rocketmq:broker-4.3.2

#slave broker01
namesrvAddr=172.16.55.185:9876;172.16.55.185:9877
brokerClusterName=HaokeCluster
brokerName=broker01
brokerId=1
deleteWhen=04
fileReservedTime=48
brokerRole=SLAVE
flushDiskType=ASYNC_FLUSH
brokerIP1=172.16.55.185
brokerIp2=172.16.55.185
listenPort=10711

#创建第2个slave broker
#slave broker01
docker create --net host --name rmqbroker04 \
-e "JAVA_OPTS=-Duser.home=/opt" \
-e "JAVA_OPT_EXT=-server -Xms128m -Xmx128m -Xmn128m" \
-v /haoke/rmq/rmqbroker04/conf/broker.conf:/etc/rocketmq/broker.conf \ -v /haoke/rmq/rmqbroker04/logs:/opt/logs \
-v /haoke/rmq/rmqbroker04/store:/opt/store \ foxiswho/rocketmq:broker-4.3.2
#slave broker02
namesrvAddr=172.16.55.185:9876;172.16.55.185:9877
brokerClusterName=ItcastCluster
brokerName=broker02
brokerId=1
deleteWhen=04
fileReservedTime=48
brokerRole=SLAVE
flushDiskType=ASYNC_FLUSH
brokerIP1=172.16.55.185
brokerIp2=172.16.55.185
listenPort=10611

#启动容器
docker start rmqserver01 rmqserver02
docker start rmqbroker01 rmqbroker02 rmqbroker03 rmqbroker04
```
### 9  docker 安装 elk

```pwd
#拉取镜像
docker pull elasticsearch:6.5.4 
#创建容器
docker create --name elasticsearch --net host -e "discovery.type=single-node" -e "network.host=172.16.55.185" elasticsearch:6.5.4
#启动
docker start elasticsearch
#查看日志
docker logs elasticsearch

#安装  elasticsearch-head
https://chrome.google.com/webstore/detail/elasticsearch-head/ffmkiejjmecolpfloofpjologoblkegm

#安装 ik
#安装方法:将下载到的elasticsearch-analysis-ik-6.5.4.zip解压到/elasticsearch/plugins/ik 目录下即可。
#如果使用docker运行
docker cp /tmp/elasticsearch-analysis-ik-6.5.4.zip elasticsearch:/usr/share/elasticsearch/plugins/ #进入容器
docker exec -it elasticsearch /bin/bash
mkdir /usr/share/elasticsearch/plugins/ik
cd /usr/share/elasticsearch/plugins/ik
unzip elasticsearch-analysis-ik-6.5.4.zip
#重启容器即可
docker restart elasticsearch
```
### 10 docker安装elastic 集群

```pwd

mkdir /haoke/es-cluster
cd /haoke/es-cluster
mkdir node01
mkdir node02
#复制安装目录下的elasticsearch.yml、jvm.options文件，做如下修改 #node01的配置:
cluster.name: es-itcast-cluster
node.name: node01
node.master: true
node.data: true
network.host: 172.16.55.185
http.port: 9200
discovery.zen.ping.unicast.hosts: ["172.16.55.185"]
discovery.zen.minimum_master_nodes: 1
http.cors.enabled: true
http.cors.allow-origin: "*"

#node02的配置:
cluster.name: es-itcast-cluster
node.name: node02
node.master: false
node.data: true
network.host: 172.16.55.185
http.port: 9201
discovery.zen.ping.unicast.hosts: ["172.16.55.185"] discovery.zen.minimum_master_nodes: 1 http.cors.enabled: true
http.cors.allow-origin: "*"

#创建容器
docker create --name es-node01 --net host -v /haoke/es- cluster/node01/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml -v /haoke/es-cluster/node01/jvm.options:/usr/share/elasticsearch/config/jvm.options -v /haoke/es-cluster/node01/data:/usr/share/elasticsearch/data elasticsearch:6.5.4
docker create --name es-node02 --net host -v /haoke/es-
cluster/node02/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml
-v /haoke/es-cluster/node02/jvm.options:/usr/share/elasticsearch/config/jvm.options
-v /haoke/es-cluster/node02/data:/usr/share/elasticsearch/data elasticsearch:6.5.4

#启动容器
docker start es-node01 && docker logs -f es-node01
docker start es-node02 && docker logs -f es-node02
#提示:启动时会报文件无权限操作的错误，需要对node01和node02进行chmod 777 的操作
#查看响应
http://172.16.55.185:9200/_cluster/health
```

### 11 docker安装rabbitmq 
```pwd
#指定版本，该版本包含了web控制页面
docker pull rabbitmq:management
#方式一：默认guest 用户，密码也是 guest
docker run -d --hostname my-rabbit --name rabbit -p 15672:15672 -p 5672:5672 rabbitmq:management
#方式二：设置用户名和密码
docker run -d --hostname my-rabbit --name rabbit -e RABBITMQ_DEFAULT_USER=user -e RABBITMQ_DEFAULT_PASS=password -p 15672:15672 -p 5672:5672 rabbitmq:management
#访问
http://本地:15672/

```

### 12 本地安装apollo 
```pwd
#下载安装包
https://github.com/ctripcorp/apollo/releases
apollo-configservice
apollo-adminservice
apollo-portal
#下载数据库脚本
https://github.com/ctripcorp/apollo/blob/master/scripts/sql/apolloconfigdb.sql
https://github.com/ctripcorp/apollo/blob/master/scripts/sql/apolloportaldb.sql
# 修改安装包里配置文件的数据库配置
application-github.properties 
配置本地数据库
#修改 环境地址/apollo-portal-1.6.1-github/config/application-env.properties 
local.meta=http://localhost:8080
dev.meta=http://localhost:8080
fat.meta=http://fill-in-fat-meta-server:8080
uat.meta=http://fill-in-uat-meta-server:8080
lpt.meta=${lpt_meta}
pro.meta=http://fill-in-pro-meta-server:8080

#修改日志文件夹访问权限
/opt/logs/100003173
sudo chmod -R 777 100003172
#启动 
sh startup.sh
#访问路径
http://localhost:8070/   http://localhost:8080/ http://localhost:8090/
apollo amdin


```

### 12 服务器安装Yapi 
```

实测有效安装方法 2020年12月20日
主要修改了以下内容：

node14 版本必须 < 15
通过官方文档的手动安装并修改部分内容
修改 config.json
删除 package-lock.json
本地主机：MacOS 10.16.7

环境：

HomeBrew
mongodb 4.4.1（通过 HomeBrew 安装）
node 14（通过 HomeBrew 安装）⚠️ 特别注意：一定要 < 15（亲测15版本Node会报依赖错误）
YApi（依赖Node & mongodb）
pm2（依赖Node 来保护YApi进程）
安装过程：
HomeBrew 略

mongodb 略
https://blog.csdn.net/sinat_27245917/article/details/108997450
node@14 略

pm2 略

YApi手动部署：
安装-手动

mkdir yapi 
cd yapi 
git clone https://github.com/YMFE/yapi.git vendors 
cp vendors/config_example.json ./config.json // ⚠️  复制完成后把内容修改为 config.json
cd vendors 
rm package-lock.json // ⚠️ 一定要删除 package-lock.json 
npm install --production --registry https://registry.npm.taobao.org 
npm run install-server  //得到账号密码
node server/app.js 
后台启动 pm2
// 报 MongoNetworkError: Authentication failed., mongodb Authentication failed 
#修改 mongodb 的数据库
一、配置MongoDB
第一步：创建数据库
use yapi
第二步：创建用户并配置权限
db.createUser({user:"username",pwd:"123456",roles:[{"role":"readWrite","db":"yapi"}]})

二、配置YApi（config.json）
"db": {
   "servername": "127.0.0.1",
   "DATABASE": "yapi",
   "port": 27017,
   "user": "username",
   "pass": "123456",
   "authSource": ""
 }
三  show dbs 命
 db.runoob.insert({"name":"菜鸟教程"})

ln -s /usr/local/node/bin/pm2 /usr/local/bin/

```
