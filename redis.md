#### 第一周 2020 04-14 2020 04-19

```pwd
#redis 集群连接
redis-cli -h ip -p 7002 -c
#redis 监控
https://zhuanlan.zhihu.com/p/95716750
redis-cli --stat
#redis 用来做什么？
记录帖子的点赞数、评论数和点击数 (hash)。
记录用户的帖子 ID 列表 (排序)，便于快速显示用户的帖子列表 (zset)。
记录帖子的标题、摘要、作者和封面信息，用于列表页展示 (hash)。
记录帖子的点赞用户 ID 列表，评论 ID 列表，用于显示和去重计数 (zset)。
缓存近期热帖内容 (帖子内容空间占用比较大)，减少数据库压力 (hash)。
记录帖子的相关文章 ID，根据内容推荐相关帖子 (list)。
如果帖子 ID 是整数自增的，可以使用 Redis 来分配帖子 ID(计数器)。
收藏集和帖子之间的关系 (zset)。
记录热榜帖子 ID 列表，总热榜和分类热榜 (zset)。
缓存用户行为历史，进行恶意行为过滤 (zset,hash)
#reids-cli 和 redis-cli --raw
\x00\x10\x01\x 是指 序列化对象时序列化器没有配的问题
redis-cli --raw 就可以了
#redis 数据结构字
String (字符串 512M)、List (列表)、Set (集合 无序不重复)、Hash (哈希 key field value 类似对象) 和 Zset (有序集合)
#怎么看key 的类型
type key; strlen key ;//字符串长度
llen key list 的大小
#list 队列和栈数据结构
let 从左边进（新元素在左边添加）（向头部添加）
> lpush books go java py
> lrange books 0 -1
py java go
左边出
> lpop books  
py java go
右边出
> rpop books 
go java py

从右边进（新元素在右边添加）（向尾部添加）
> rpush books go java py
> lrange books 0 -1
go java py 
> rpop books 
py java go
> lpop books  
go java py
#对象信息用 String 还是 hash 的好？
https://stackoverflow.com/questions/16375188/redis-strings-vs-redis-hashes-to-represent-json-efficiency
访问的属性值比较少的用hash 多的用 String  不管怎么样 要压缩json 字符串

#锁为什么会被其它线程删除呢？
A在0秒设置一个有效期为2秒的锁。 2.B在3秒时申请会拿到锁（因为A设置的锁已经过期） 3. A在4秒时，做完事情，以为锁还在自己手上，就去删除锁。 B拿到的锁会被A删掉。 这时候如果有C申请锁，B和C就会同时持有锁。

#如果某个定时任务需要加锁，但是执行的时间的时间不确定，也就是Redis锁的时间也不确定，那么该如何处理？
使用redisson 有个看门狗机制，后台异步启动一个线程定时(默认10s)去检查锁是否过期(锁不需要设置过期时间，默认30s过期)，如果没有过期就延长锁的过期时间，往复循环，知道当前线程释放锁看门狗才会退出

#位图的签到用法
u:sign:1000:201904表示ID=1000的用户在2019年4月的签到记录。
# 用户2月17号签到
SETBIT u:sign:1000:201904 0 1 # 偏移量是从0开始，第一天
SETBIT u:sign:1000:201904 2 1 # 偏移量是从0开始，第三天
SETBIT u:sign:1000:201904 4 1 # 偏移量是从0开始，第五天
# 检查4月5号是否签到
GETBIT u:sign:1000:201904 4 # 偏移量是从0开始
# 统计4月份的签到次数
BITCOUNT u:sign:1000:201904 
3  3次
# 获取4月份前5天的签到数据
BITFIELD u:sign:1000:201904 get u5 0
10101 ->21(从左往右 1 2 4 8 16) 1+4+16=21
# 获取4月份首次签到的日期
BITPOS u:sign:1000:201904 1 # 返回的首次签到的偏移量，加上1即为当月的某一天
0  那么就是 4.1号第一次签到


```

#### 第二周 2020 04-20 2020 04-26

```pwd
#HyperLogLog 数据去重 UV数据统计
pfadd sw 001 002 003 004
1 //成功
pfadd sw 004 0 //没有成功
pfcount sw   //4
#RedisBloom 布隆过滤 缓存穿透会使用到布隆过滤器
https://oss.redislabs.com/redisbloom/Quick_Start/
git clone https://github.com/RedisBloom/RedisBloom.git
cd redisbloom
make
#启动加载模块
redis-server  --loadmodule /Users/fuxinghua/devloop/RedisBloom/redisbloom.so
log  Module 'bf' loaded from /Users/fuxinghua/devloop/RedisBloom/redisbloom.so //配置好了
#测试
bf.add user 1 
1//成功
bf.add user 2 //bf.madd user 3  4
type user //MBbloom--
bf.exists user 3 //1 存在
bf.exists user 5 //0 不存在 //bf.mexists user 3 4
//java 的api 操作
https://github.com/Baqend/Orestes-Bloomfilter
#利用 zset 的score 达到一个范围窗口的效果 进行限流
https://www.cnblogs.com/viscu/p/9822866.html
pipeline.zadd(key,nowTs,nowTs+""); //value和score都使用毫秒时间戳
pipeline.zremrangeByScore(key,0,nowTs-period*1 000); //移除时间窗口之前的行为记录，剩下的都是时间窗口内的
Response<Long> count=pipeline.zcard(key); //获得[nowTs-period*1000,nowTs]的key数量
#漏斗限流
安装 redis-cell   https://github.com/brandur/redis-cell 推荐下载tar包安装
#GeoHash 地图位置 附近的人 功能 底层 zset
geoadd city 114.175932 30.354265 wuhan
geoadd city 116.242581 39.541688 beijing
geoadd city 120.085167 30.144620 hangzhou
geoadd city 113.271620 30.214504 xiantao
geoadd city 113.545922 30.552939 xiaogan
#两点距离(distance)
geodist city wuhan hangzhou km //568.1838km
#获取城市位置(position)
geopos city wuhan // 114.17593270540237427 (lng) 30.35426555281202354(lat)
#附近的城市排序 radius
georadiusbymember city wuhan 100 km count 3 asc //100 公里范围内 wuhan xiantao
#可选参数
witdcoord:经纬度坐标(coord)
withdist: 距离
withhash： hash 值
ex；georadiusbymember city wuhan 100 km withdist  count 2 asc 
# 附近的城市 数据很多的话 用ES集群做经纬度的运算
georadius city 114 30  100 km withdist asc
//georadius key longitude latitude radius m|km|ft|mi [WITHCOORD] [WITHDIST] [WITHHASH] [COUNT count] [ASC|DESC] [STORE key] [STOREDIST key]
#scan
 scan 0 match s* count 1 //匹配 s 开头的key 一次 返回1 个直到结束
#定位大key
redis-cli -h 127.0.0.1 -p 6379 --bigkeys

```

#### 第三周 2020 04-27 2020 05-03
```
#线程 IO 模型
非阻塞 IO和 事件轮询 (多路复用) NIO 核心就是 buffer 和 轮询  先把数据写到缓冲区在提交
指令队列/响应队列 进行处理和响应的排队
#管道压力测试
redis-benchmark -t set -q
SET: 127226.46 requests per second //set 指令QPS 大约 13w/s
redis-benchmark -t set -P 2 -q  //-P=2 2管道
SET: 179856.11 requests per second //set 指令QPS 大约 18w/s
#内存回收机制
如果是del key 内存并没有被回收 而是等待新的key来使用
如果是 flushdb 则会立刻回收所有的内存(禁用 flushdb 应该用flushall指令)
#查看memory 内存信息
info memory 
#redis 快照同步和无盘同步 之间的主要区别在哪里。
快照同步，需要先遍历当前内存中的数据生成快照，然后持久化到磁盘文件，然后再将快照文件传送给从节点。而无盘同步，则省去快照持久到磁盘文件的步骤，遍历当前内存中数据时，生成快照就直接发送给从节点了，省去持久化到磁盘的操作。
#redis cluster
将所有数据划分为 16384 的 slots 然后对key值使用 crc16 算法进行 hash 得到一个整数值，然后用这个整数值对 16384 进行取模来得到具体槽位。
#将key 存储到指定的slots
https://redis.io/topics/cluster-spec#keys-hash-tags 给需要用到的key加相同的hash tag，保证分配到同一个slot，就可以正常使用这类多个key的命令了 和事物管理

```



