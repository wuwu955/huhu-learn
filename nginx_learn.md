
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


### 3 对称加密和非对称加密

```pwd
对称加密 用一样的密钥去加解密 
非对称加密是 公钥加密 私钥解密
```

### 4 location 匹配规则

```pwd
1 如果是 =xx 那么事精确匹配 匹配了就不走了 如果是^～ xx 匹配了也不走了 
2 以上不上 记住最长匹配，接着再顺序执行正则匹配(如果没有禁止正则匹配的话！）如果没有正则匹配上就用最长匹配
有的就用正则匹配

```
