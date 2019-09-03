# Elastic Search 简记

## 一 2019年09月01日

### 1 docker 中 启动es  

```pwd
#cd /Users/fuxinghua/devloop/config
# docker-compose.yaml 
这个 compose 第一章 2.3
https://github.com/geektime-geekbang/geektime-ELK
#启动
docker-compose up
#停止容器
docker-compose down

```

### 2 访问路径

```pwd
#es 版本信息
http://localhost:9200/
#cerebro 监控面板
http://localhost:9000
#kibana 操作工具
http://localhost:5601

```

### 3 index api 

```pwd
Index 相关 API

#查看索引相关信息
GET kibana_sample_data_ecommerce
#查看索引的文档总数
GET kibana_sample_data_ecommerce/_count
#查看前10条文档，了解文档格式
POST kibana_sample_data_ecommerce/_search
{
}

#_cat indices API
#查看indices
GET /_cat/indices/kibana*?v&s=index
#查看状态为绿的索引(状态可用的)
GET /_cat/indices?v&health=green
#按照文档个数排序（索引里的文档个数）
GET /_cat/indices?v&s=docs.count:desc
#查看具体的字段
GET /_cat/indices/kibana*?pri&v&h=health,index,pri,rep,docs.count,mt
#How much memory is used per index?
GET /_cat/indices?v&h=i,tm&s=tm:desc


```

### 4 倒排索引

```pwd
#分词api 
POST _analyze
{
  "analyzer": "standard",
  "text": "Mastering Elasticsearch"
}

#respone
{
  "tokens" : [
    {
      "token" : "mastering",
      "start_offset" : 0,
      "end_offset" : 9,
      "type" : "<ALPHANUM>",
      "position" : 0
    },
    {
      "token" : "elasticsearch",
      "start_offset" : 10,
      "end_offset" : 23,
      "type" : "<ALPHANUM>",
      "position" : 1
    }
  ]
}
```

```pwd
正排索引是文档ID到文档内容和关键词 类似mysql 主键定位到行记录
倒排索引是 单词到文档ID   类似行记录中的一个普通索引定位到对应的主键ID
就是存储上 关键词记录着出现的文档ID 和对应的 position 还有offset 然后根据这三个去
找记录和高亮显示

```

### 5 分词器的使用

```pwd
#Standard Analyzer -默认分词器 按词切分 小写处理
#Simple Analyzer – 按照非字母切分（符号被过滤），小写处理
#Stop Analyzer – 小写处理，停用词过滤（the，a，is）
#Whitespace Analyzer – 按照空格切分，不转小写
#Keyword Analyzer – 不分词，直接将输入当作输出
#Patter Analyzer – 正则表达式，默认 \W+ (非字符分隔)
#Language – 提供了30多种常见语言的分词器

#列子
#english
GET _analyze
{
  "analyzer": "english",
  "text": "2 running Quick brown-foxes leap over lazy dogs in the summer evening."
}

```

​    Docker  下安装分词插件

```

1.进入es的容器并启动bash。 命令 docker exec -it es7_01 bash
注：es7_01 即容器名称
2.第一步成功你会发现你已经在容器内部，此时输入 pwd 命令会发现自己处于/usr/share/elasticsearch 路径。
此时即可输入插件安装命令 bin/elasticsearch-plugin install analysis-icu 
等待插件下载并安装完毕
3.输入exit退出容器bash。
4.如法炮制es7_02并安装插件。
5.docker-compose restart 重启容器
6.重启后，检查安装是否成功，输入 curl 127.0.0.1:9200/_cat/plugins，输出：
es7_01 analysis-icu 7.2.0
es7_02 analysis-icu 7.2.0

```

###  6 search api

```pwd
es: GET index_name/_search?q=filedName:query

#URI Query
GET kibana_sample_data_ecommerce/_search?q=customer_first_name:Eddie
GET kibana*/_search?q=customer_first_name:Eddie
GET /_all/_search?q=customer_first_name:Eddie

#REQUEST Body profile 分析查询
POST kibana_sample_data_ecommerce/_search
{
	"profile": true,
	"query": {
		"match_all": {}
	}
}
#脚本查法 适用于计算


GET kibana_sample_data_ecommerce/_search
{
  "script_fields": {
    "new_field": {
      "script": {
        "lang": "painless",
        "source": "doc['order_date'].value+'hello'"
      }
    }
  },
  "query": {
    "match_all": {}
  }
}

更改 Mapping 的字段类型 必须重新 reindex api
```

### 