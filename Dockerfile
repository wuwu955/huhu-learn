FROM openjdk:8

# 仅适用于java服务。前端服务和go应用不支持
MAINTAINER zw <zw@qq.com>

# SW_AGENT_NAME 表示服务名，同时也是你编译后jar包的前缀名称。需要根据实际情况更改
ENV SW_AGENT_NAME demo
# JAR_NAME 表示编译后的jar包名称，与SW_AGENT_NAME变量挂钩。需要根据实际情况更改
ENV JAR_NAME ${SW_AGENT_NAME}-1.0-SNAPSHOT.jar
# APP_CONFIG 使用本地文件启动服务时需要填写，例如--spring.config.location=/data/config/application.yml；使用nacos作为配置中心则不需要填写
ENV APP_CONFIG "--spring.config.location=/data/config/application.yml"
# APP_BASE_DIR 表示服务的工作目录。默认即可
ENV APP_BASE_DIR "/data/app"
# LOG_BASE_DIR 表示服务的日志目录。默认即可
ENV LOG_BASE_DIR "/data/logs"
# JAR_FILE_PATH 表示容器中jar包的实际位置和jar包的实际名称。默认即可
ENV JAR_FILE_PATH "${APP_BASE_DIR}/app.jar"
# SKY_OPTS 表示接入skywalking的配置。默认即可
# NACOS_OPTS 表示接入nacos的配置。默认即可
# JAVA_OPTS 表示jvm虚拟机配置。默认即可
ENV SKY_OPTS="" \
    NACOS_OPTS="" \
    JAVA_OPTS="-server -Xmx2g -Xms1g -Xss256m -XX:MaxDirectMemorySize=256m \
-XX:+UseG1GC -verbose:gc -XX:+PrintCommandLineFlags -XX:+ExplicitGCInvokesConcurrent \
-Xlog:gc*,safepoint:${LOG_BASE_DIR}/gc.log:time,uptime:filecount=5,filesize=50M \
-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=${LOG_BASE_DIR}/gc.hprof"
# 默认即可
RUN /bin/cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo 'Asia/Shanghai' > /etc/timezone \
    && mkdir -p ${APP_BASE_DIR} \
    && mkdir -p ${LOG_BASE_DIR}
# 设置工作目录。默认即可
WORKDIR /data/app
# 添加jar包到容器中。默认即可
ADD target/${JAR_NAME} ${JAR_FILE_PATH}
# EXPOSE 表示容器暴露的端口。请遵循以下规则(需要根据实际情况更改)：
# 1. 前端服务端口为3000,后端服务为80,网关服务为8080
# 2. 该端口必须和服务运行端口保持一致。否则服务会异常
# 3. tke的服务发现依赖该端口，因此必须要填写，且真实有效。
# 4. 如需暴露多个端口，端口依次递增，以空格隔开。如：
#   前端服务 EXPOSE 3000 3001 3002 3003 3004
#   后端服务 EXPOSE 80 81 82 83
#   网关服务 EXPOSE 8080 8081
EXPOSE 8013
# 执行启动命令。默认即可
ENTRYPOINT exec java  ${JAVA_OPTS} ${SKY_OPTS} ${NACOS_OPTS} -jar ${JAR_FILE_PATH} ${APP_CONFIG}
