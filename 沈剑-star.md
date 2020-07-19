## 沈剑-追星笔记

### 1 自己不知道自己的核心竞争力是什么 迷茫？

```pwd
1.你正在做什么，工作来之不易，努力做好手头的事情肯定不是坏事，工作中提升是最快的；
2.工作之外，想成为专家，把领域内的知识，工具，思路搞透。看书，记笔记，和前辈请教，是好的学习方法。
坚持几年，你一定能成为领域内top的专家；
3 给自己定一个目标，例如：每周健身3次，每天学英语半小时，每2周看1本书，每周写一篇读书笔记。
这个浮躁的社会，只要够努力，根本轮不到拼智商。

```

### 2 30亿日志，多条件检索，后台分页查询，有什么好的方案么？

```pwd
结合本例，日志量大，模式固定，建议：
（1）最建议，使用Hive存储，使用索引的方式实现日志后台检索需求；
（2）如果扩展性要求稍高，可以使用ES实现存储与检索，使用水平扩展来存储更大的数据量；
 https://mp.weixin.qq.com/s/3CwbmAIqpq8wSYrZaVTqfw
```

### 3 1000亿身份证信息，MD5查询，5w并发，有什么好的方案么？

```pwd

https://mp.weixin.qq.com/s/Cy2-3NykK5wOP-Fth1aY0g

```

### 4 单库自增主键在后期分库的时候怎么保证现在的新库的ID 和原来的不冲突？

```pwd

假设由单库拆分为3库，可以这么玩：
（1）做一个1主2从数据库集群，相当于每条数据复制成了3份；
（2）将路由算法，设为取模hash算法，%3；
（3）第一个库，%3=0，把余1和余2的uid删掉；
（4）第二个库，%3=1，把余0和余2的uid删掉；
（5）第三个库，%3=2，把余0和余1的uid删掉；
（6）将每个库的自增步长设置为3，这样每个库的id生成就不会重复了；
（7）升级用户中心，按照路由算法查询uid数据；

https://mp.weixin.qq.com/s/HeXfT9bEqqJgqqPWxWh35Q
```

### 5 处理亿级数据的“定时任务”，如何缩短执行时间？

```pwd

总结，对于这类一次性集中处理大量数据的定时任务，优化思路是：
（1）同一份数据，减少重复计算次数；
（2）分摊CPU计算时间，尽量分散处理（甚至可以实时），而不是集中处理；
（3）减少单次计算数据量；
 https://mp.weixin.qq.com/s/aN-M8YcwXNE462HaVrQ6ig

这里 结合工作中的我慧记记录各个时间段的统计
```

### 6 粉丝关系链，10亿数据，如何设计？

```pwd
总结
关系链业务是一个典型的多对多关系，又分为强好友与弱好友
数据冗余是一个常见的多对多业务数据水平切分实践
冗余数据的常见方案有三种
         （1）服务同步冗余
         （2）服务异步冗余
         （3）线下异步冗余
数据冗余会带来一致性问题，高吞吐互联网业务，要想完全保证事务一致性很难，常见的实践是最终一致性
最终一致性的常见实践是，尽快找到不一致，并修复数据，常见方案有三种
         （1）线下全量扫描法
         （2）线下增量扫描法
         （3）线上实时检测法
         
https://mp.weixin.qq.com/s/S1hU7oX7rum01g_Xwixunw

```

### 7 几万条群离线消息，如何高效拉取，会不会丢？

```pwd
总结 
群消息还是非常有意思的，做个简单总结：
(1)群离线消息一般采用拉取模式，只存一份，不需要为每个用户存储离线群msg_id，只需存储一个最近ack的群消息id/time；
(2)为了保证消息可达性，在线消息和离线消息都需要ACK；
(3)离线消息过多，可以分群拉取、分页拉取等优化；
画外音：还可按需拉取，登录不拉取，点进群再拉取。
(4)如果收到重复消息，需要msg_id去重，让用户无感知；
https://mp.weixin.qq.com/s/-KHrxGsBaEvIc4AOkb0_vA

这里 结合工作中的我慧记系统消息推送表设计


```

### 8 盘口数据频繁变化，100W用户如何实时通知？

```pwd
总结
长连接比短连接性能好很多倍
推送量巨大时，推送集群需要与业务集群解耦
推送量巨大时，并发推送与批量推送是一个常见的优化手段
写入量巨大时，水平切分能够扩容，MQ缓冲可以保护数据库
业务复杂，读取量巨大时，加入缓存，定时计算，能够极大降低数据库压力

https://mp.weixin.qq.com/s/QcPicGRkaFENP6IzMRZMaQ

```

### 9  每秒20W次并发的短文本分词检索，架构如何设计？(这个很酷)

```pwd
trie :字典树
总结
短文本，高并发，支持分词，不用实时更新的检索场景，可以使用：
（1）ES，杀鸡用牛刀；
（2）分词+DAT(trie)；
（3）分词+内存hash；
等几种方式解决。

https://mp.weixin.qq.com/s/3FMZ2byF2ltSKw3oXnMzTg
```

### 10 并发扣款，如何保证数据的一致性？（这个思路真的是奇特）

```pwd
一 具体到这个case，只需要将：
  UPDATE t_yue SET money=$new_money WHERE uid=$uid;
  升级为：
  UPDATE t_yue SET money=$new_money WHERE uid=$uid AND money=$old_money;
  即可。保证一条线程写入修改数据
  set操作，其实无所谓成功或者失败，业务能通过affect rows来判断：
  写回成功的，affect rows为1
  写回失败的，affect rows为0
  
二 结合上面的sql 写法会存在CAS ABA 问题
  ABA 简而言之 就是
  1 线程读取出指定内存地址的数据A，加载到寄存器
  2 线程占到cpu读取出指定内存地址的数据A，加载到寄存器，并修改值B到内存地址
  3 线程又占到cpu读取出指定内存地址的数据B 并修改值A到内存地址
  最后1 线程修改成功 但是A 已经发生了变化
  所以上面的sql 修改为（加version）
  UPDATE t_yue SET money=$new_money, version=$version_new WHERE uid=$uid AND version=$version_old

三 并发扣款一致性 幂等性问题
一般使用：
select&set，配合CAS方案
而不使用：
set money-=X方案

微信文章地址
https://mp.weixin.qq.com/s/QSpBDlW1KktJ8iHaYcO2rw
https://mp.weixin.qq.com/s/03ndQ7k2ehQzYVDYgCpWHQ
https://mp.weixin.qq.com/s/xXju0y64KKUiD06QE0LoeA

```

### 11 架构师之路精选文章

```pwd
2018 架构师之路精选100篇
架构设计，运维，数据库，数据结构算法，缓存
https://mp.weixin.qq.com/s/V1hGa6D9aGrP6PiCWEmc0w
2019 架构师之路精选120篇
https://mp.weixin.qq.com/s/syli7vs7Jw_VOTl5B2YUqg
```



### 12 chmod 755 究竟是什么鬼？

```PWD
文件创建后，有三种访问方式：
读(read)：显示内容
写(write)：编辑内容，删除文件
执行(execute)：执行文件

针对用户，文件有三类权限：
创建人(user)权限：创建文件的人
组(group)用户权限：和拥有者处于同一用户组的其他人
其他(other)用户权限
3位对应位的对应数字加起来，最终就是三类用户的最终权限。
例子
chmod 755 xxx.sh
第一位7：4+2+1，创建者，可读可写可执行
第二位5：4+1，组用户，可读可执行
第三位5：4+1，其他用户，可读可执行

https://mp.weixin.qq.com/s/OwoOYbmElD0S6WMQ2LNS1A


```
### 13 跨库分页的几种常见方案（最后页的数据）

```pwd
将
select xxx from t order by yyy limit 0,10
转化为
select xxx from t where yyy>next_begin  limit 10
就是说先where 条件过滤 在分页数据

https://mp.weixin.qq.com/s/H_2hyEqQ70Y_OoFZh_P_5A
```

### 14 每秒100W请求，12306秒杀业务，架构如何优化

```pwd
秒杀业务，可以使用典型的服务化分层架构：
 端（浏览器/APP） 限制用户提交次数
 站点层 登陆授权 对同一个uid的请求进行计数和限速 超过的返回上一次的页面缓存 服务水平扩容和降级
 服务层 对列（写请求 mq ）和缓存（读请求 redis）
 数据层 分库分表 搭建高可用集群
总结
 对于秒杀系统，除了产品和业务上的折衷，架构设计上主要有两大优化方向：
（1）尽量将请求拦截在系统上游；
（2）读多写少用缓存；
（3）业务折衷；

https://mp.weixin.qq.com/s/WSocbTKWYBqOSfimdfm_JA
秒杀相关设计 其他资料
https://github.com/qiurunze123/miaosha
```
### 15 即时抽奖，等概论中奖，如何实现

```pwd
1 按时间纬度将奖品散列，最接近中奖时间点的用户中奖（这个是比较好的）
2 将5个奖品随机分布在序号1～100中，比如 11，23，34，55，97。然后开始抽奖，用户进来的序号跟奖品序号对上就中奖，对不上就不中。这样所有用户概率一样，抽奖公平，能保证100个人进来，能把所有奖品派掉。开奖前把没发出的奖品通过数据库改下发给个测试账号（为了保证发完奖品，的牺牲）

```
### 16 订单30分钟不支付自动取消是如何实现的？
```pwd
一 DelayQueue +redis 感觉写复杂了
（1）用户下单完成以后，把订单ID插入到DelayQueue中，同时插入到Redis中。
（2）30分钟之内，用户付款完成，则从DelayQueue中删除，从Redis中删除。
（3）超过30分钟，DelayQueue中的订单ID出队，查询数据库，改状态为取消，删除redis。
（4）如果30分钟之类，服务器重启，则服务器重新启动以后，从redis中读取待订单，重新插入到DelayQueue。
 https://mp.weixin.qq.com/s/8BCGHIXOppztvijD-JRakw
 二 redis 监听key 和 数据库扫描 reids 并发高的时候容易丢失key 数据库扫描失效性不高
 
```

### 17 系统后台数据导出接口报404？
```pwd
数据过多 接口响应时间超过nginx 的超时时间 返回404 

https://www.cnblogs.com/wujf-myblog/p/10836954.html
```

### 18 shiro和dubbo 和 mybaits-plugs 租户ID 做数据级别的权限？
```pwd
#dubbo fiter 
https://github.com/shbeyond/midai-pay
https://www.cnblogs.com/yufan27209/p/7324190.html
#todo 代码实现
```

### 19 jwt token 过期刷新？
```pwd
假如 token 三十分钟过期 ，过期时间少于10 分钟的时候，有请求进来可以延长 token 的过期时间；过期了，让他再掉登陆接口自己去生成token，之前在拦截器里做的每次都刷新的动作太耗频繁了 这个方案还不错
```
### 20 限制接口重复请求？
```pwd
在请求上加 token，然后弄个过滤器或者 AOP 判断下 token 是否请求过了，这个 token 一个简单的生成方法可以用毫秒级别的时间戳。问题中的业务场景需要在业务逻辑里判重，超时重发的时候里的 token 重新生成，重复提交的两次请求的 token 是一样的。 前端生成的token 只要后台没有返回数据 就不重新生成。
```

### 21 查询的fallback设计 es 失败查询数据库的场景？
```pwd
• 采用责任链模式处理这种情况，你无非就是想获取数据，如果当前处理者没有拿到数据，就进行下一个，否则返回。try catch 处理的是异常，不是业务上的回退。
https://blog.csdn.net/afei__/article/details/80677711
```
### 22 Mysql 值增ID 不连续？
```pwd
1 InnoDB 引擎的自增值，其实是保存在了内存里 “如果发生重启，表的自增值可以恢复为 MySQL 重启前的值”
2 唯一键冲突是导致自增主键 id 不连续的第一种原因 事务回滚也会产生类似的现象
3 批量插入 replace … select … ，load data , insert into t1(name) select name from t2;
4 混合插入(mixed-mode insert)
#AUTO_INCREMENT=8
INSERT into order_rab (id,customer_id,kind) VALUES(1,1,1),(2,2,2),(3,3,3),(null,4,4);
#AUTO_INCREMENT=6
INSERT into order_rab (id,customer_id,kind) VALUES(1,1,1),(null,2,2),(3,3,3),(null,4,4);
其他资料
https://mp.weixin.qq.com/s/lSPI6UUJiZLSgV9RqqP1Rg
https://mp.weixin.qq.com/s/jVO4f1DYoinmP3-eK9AOYA
```
### 23 关于dubbo学习的几个github
```pwd
1 https://github.com/wuwenhui0917/dubbo-ecs
2 https://github.com/dubboclub/dubbo-plus
3 https://github.com/everythingbest/dubbo-postman  
4 https://github.com/lshm/dubbo-gzip //dubbo 对数据进行压缩
see issues 

https://github.com/apache/dubbo/issues/5951  请求插件的
https://github.com/apache/dubbo/issues/5461  授权的
https://github.com/apache/dubbo/issues/3386  自定义异常
https://github.com/apache/dubbo/issues/2789  可以实现动态添加和删除filter
https://github.com/apache/dubbo/issues/6048  请求和响应的大小限制
https://github.com/apache/dubbo/issues/685  超大cache文件内存溢出问题
http://dubbo.apache.org/zh-cn/docs/dev/impls/filter.html 改配置

```
### 24 关于dubbo group 和 payload 负载的用法
```
group 配置  
ServiceConfig ReferenceConfig
RegistryConfig
payload 配置 默认是 8M
ProtocolConfig 
ProviderConfig
ex
 <dubbo:provider id ="默认dubbo" group="xxx" payload="1048576" /> //1M
 <dubbo:service interface="com.ikeep.platform.sdk.tdk.TdkSetSdk" ref="tdkSdkImpl"
                   register="true" protocol="dubbo" timeout="30000" provider="默认dubbo" />
```
### 25 微服务设计思想
```
1 很多微服务架构中还包括一个监控者的角色，通过监控者进行服务的管理和流量的控制。
使用微服务最重要的是做好业务的模块化设计，模块之间要低耦合，高聚合，模块之间的依赖关系要清晰简单。只有这样的模块化设计，才能够构建出良好的微服务架构。如果系统本身就是一团遭，强行将它们拆分在不同的微服务里，只会使系统变得更加混乱。
使用微服务的时候，有几个重要的使用模式，需要关注：一个是事件溯源，一个是命令与查询隔离，还有一个是断路器以及关于超时如何进行设置。
2 负载均衡
DNS 负载均衡
目前主要的 DNS 服务商和 DNS 软件都支持 DNS 域名解析负载均衡。DNS 域名解析负载均衡的主要问题有两个方面。一方面它依然是要将 Web 服务器的 IP 地址暴露给浏览器，产生安全问题。另一方面，很多时候，DNS 域名解析服务器是在互联网应用系统之外的一个服务器，它由域名解析服务商提供，不在我们的控制范围之内，所以当我们的服务器不可用的时候，DNS 域名解析服务器并不知道，它依然会将用户请求分发过来。而且域名解析并不是每一次请求都进行解析的，即使我们去域名解析服务商的机器上去更新了域名解析对应的 IP 列表，这个更新也不会立即生效，依然会有大量的请求到达我们的应用服务器。那么这些已经宕机的、不可用的服务器就无法完成用户的需求，在用户看起来就是我们的系统不可用。
虽然 DNS 域名解析负载均衡有这样的一些问题，但是在实践中大型互联网系统几乎都使用域名解析负载均衡，主要原因是在于，这些大型互联网系统，比如像淘宝、Facebook、百度这些系统，根据域名解析出来的 IP 地址，并不是真正的 Web 服务器 IP 地址，是负载均衡服务器的 IP 地址，也就是说这些大型互联网系统，它们都采用了两级负载均衡机制，DNS 域名解析进行一次负载均衡解析出来的 IP 地址是负载均衡服务器的 IP 地址，然后由负载均衡服务器，再做一次负载均衡，将用户的请求分发到应用服务器，这样的话，我们的应用服务器的 IP 地址就不会暴露出去。同时由于负载均衡服务器通常是比较高可用的，也不存在应用程序发布的问题，所以很少有可用性方面的问题。
数据链路层负载均衡
为了解决这个问题，将负载均衡的数据传输，再往下放一层，放到了数据链路层，实现数据链路层的负载均衡。在这一层上，负载均衡服务器并不修改数据包的 IP 地址，而是修改网卡的 MAC 地址。而应用服务器和负载均衡服务器都使用相同的虚拟 IP 地址，这样 IP 路由就不会受到影响，但是网卡会根据自己的 MAC 地址选择负载均衡发送到自己的网卡的数据包，交给对应的应用服务器去处理，处理结束以后，当他把响应的数据包发送到网络上的时候，因为 IP 地址没有修改过，所以这个响应会直接到达用户的浏览器，而不会再经过负载均衡服务器。工作原理如下图所示

```
### 26 ShardingSphere 技术
```
https://github.com/apache/shardingsphere/issues/650
```
