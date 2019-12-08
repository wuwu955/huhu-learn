
## 一 2019年12月08日

### 1 配置静态资源服务器

```pwd
	#编辑
	vim nginx.conf
  location / {
           # root   html;
            alias /Users/fuxinghua/desktop/crm/wx/; //资源文件夹
            autoindex on; //以索引树形式显示
           # proxy_pass http://localhost:8081;
           # index  index.html index.htm;
       }
  #重启
  nginx -s reload
```

### 2 配置 https 

```pwd
#查看 nginx 是否安装 http_ssl_module 模块
 nginx -V|grep http_ssl_module
#liunx 安装  yum install python2-certbot-nginx  来完成


```

