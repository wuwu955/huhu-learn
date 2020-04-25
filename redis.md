#### 第一周 2020 04-14 2020 04-19

```pwd
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







```

