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







