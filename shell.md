

## Shell  脚本

### 一 快速启动Java服务

```shell
####!/bin/bash
#这里可替换为你自己的执行程序，其他代码无需更改
APP_NAME=jxc-1.0.jar
LOG_NAME=/home/app/ikeepParent/jxc/logs/jxc.log 

# JAVA OPTIONS jvm 参数 这里可以配置调优项
JAVA_OPTS="-Xms512M -Xmx512M"

#使用说明，用来提示输入参数
usage() {
    echo "Usage: sh 执行脚本.sh [start|stop|restart|status]"
    exit 1
}

#检查程序是否在运行
is_exist(){
  pid=`ps -ef|grep $APP_NAME|grep -v grep|awk '{print $2}' `

  #如果不存在返回1，存在返回0     
  if [ -z "${pid}" ]; then
   return 1
  else
    return 0
  fi
}

#启动方法
start(){
  is_exist
  if [ $? -eq "0" ]; then
    echo "${APP_NAME} is already running. pid=${pid} ."
  else
    nohup java -jar $JAVA_OPTS $APP_NAME >$LOG_NAME 2>&1 &
  fi
}

#停止方法
stop(){
  is_exist
  if [ $? -eq "0" ]; then
    kill -9 $pid
  else
    echo "${APP_NAME} is not running"
  fi  
}

#输出运行状态
status(){
  is_exist
  if [ $? -eq "0" ]; then
    echo "${APP_NAME} is running. Pid is ${pid}"
  else
    echo "${APP_NAME} is NOT running."
  fi
}

#重启
restart(){
  stop
  start
}

#根据输入参数，选择执行对应方法，不输入则执行使用说明
case "$1" in
  "start")
    start
    ;;
  "stop")
    stop
    ;;
  "status")
    status
    ;;
  "restart")
    restart
    ;;
  *)
    usage
    ;;
esac
```

### 二 开机启动zk

```shell
## 1 初始化脚步
vim /etc/init.d/zookeeper
## 2 复制下面的脚本
#!/bin/bash
#chkconfig:2345 20 90
#description:zookeeper
#processname:zookeeper
ZK_PATH=/opt/zookeeper
export JAVA_HOME=/opt/jdk1.8.0_152
case $1 in
start) sh $ZK_PATH/bin/zkServer.sh start;;
stop) sh $ZK_PATH/bin/zkServer.sh stop;;
status) sh $ZK_PATH/bin/zkServer.sh status;;
restart) sh $ZK_PATH/bin/zkServer.sh restart;;
*)echo"requirestart|stop|status|restart";;
esac

## 3 设置service 方式
chkconfig--add zookeeper
chmod +x /etc/init.d/zookeeper

```



### 三 开机启动dubbo-admin

```shell

## 1 初始化脚步
vim /etc/init.d/dubbo-admin
## 2 复制下面的脚本
#!/bin/bash
#chkconfig:2345 20 90
#description:dubbo-admin
#processname:dubbo-admin
ZK_PATH=/opt/dubbo-admin
export JAVA_HOME=/opt/jdk1.8.0_152
case $1 in
start)
 echo"StartingTomcat..."
 $CATALANA_HOME/bin/startup.sh
 ;;
stop)
 echo"StoppingTomcat..."
 $CATALANA_HOME/bin/shutdown.sh
 ;;
 restart)
 echo"StoppingTomcat..."
 $CATALANA_HOME/bin/shutdown.sh
 sleep2
 echo
 echo"StartingTomcat..."
 $CATALANA_HOME/bin/startup.sh
 ;;
 *)
 echo"Usage:tomcat{start|stop|restart}"
 ;;esac


#chkconfig--adddubbo-admin加入权限
chkconfig--add dubbo-admin
chmod +x /etc/init.d/dubbo-admin








```

























