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

### 11 架构师之路18年精选100篇

```pwd
架构设计，运维，数据库，数据结构算法，缓存
https://mp.weixin.qq.com/s/V1hGa6D9aGrP6PiCWEmc0w
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


