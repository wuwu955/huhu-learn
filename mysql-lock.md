## Mysql 锁知识点

### 一 锁的类型是哪些

```pwd
1 锁按照 范围来说分全局锁（flush tables with read lock）、表锁（table lock）、页面锁(page lock)、行锁(record lock)，按照数据管理划分 读锁(lock in share mode )和写锁(for update)  插入意向锁（intent lock）
2 MyISAM 存储引擎只有表锁 不支持行锁 innodb 存储引擎 支持行锁
3 update insert delete 隐式的排他锁
```

### 二 什么情况下产生锁

```pwd
1 全局锁 数据备份的时候 使用全局锁 保存当前数据库数据 防止数据发生变化 例如 mysqldum -使用参数–single-transaction 的时候，导数据之前就会启动一个事务，来确保拿到一致性视图.

2 表锁 MySQL里面表级别的锁有两种：一种是表锁，一种是元数据锁（meta data lock，MDL)。表锁的语法是 lock tables … read/write。 限制其他线程访问也限制了自己的操作。
MDL 是为了数据在增删改查的过程中保持数据表结构不被修改加的表锁。因此，在 MySQL 5.5 版本中引入了 MDL，当对一个表做增删改查操作的时候，加 MDL 读锁；当要对表做结构变更操作的时候，加 MDL 写锁。所以修改表结构注意 避免线上修改ddl
先看看有没有其他未提交的事物 等其他事物提交了在进行修改表结构 可用工具是 pt-osc

3 页锁就是在页的粒度上进行锁定，锁定的数据资源比行锁要多，因为一个页中可以有多个行记录。当我们使用页锁的时候，会出现数据浪费的现象，但这样的浪费最多也就是一个页上的数据行。页锁的开销介于表锁和行锁之间，会出现死锁。锁定粒度介于表锁和行锁之间，并发度一般。

4 行锁 顾名思义，行锁就是按照行的粒度对数据进行锁定。锁定力度小，发生锁冲突概率低，可以实现的并发度高，但是对于锁的开销比较大，加锁会比较慢，容易出现死锁情况。

```

### 三 锁等待和死锁的产生

1.innodb 存储引擎的锁的实现是根据索引的 加锁的范围要看索引树扫描的数据范围

2.锁等待 session b 单方面进入锁等待时间

```sql
session A
BEGIN;
UPDATE t set c =10 where id =0

session B
UPDATE t set c =11 where id =0

1205 - Lock wait timeout exceeded; try restarting transaction, Time: 51.106000s
--这里还是行锁 的情况
```

3.死锁 场景  互相等待释放锁导致死锁 但是session A的事物一直还未提交中 session B自动rollback 了 

```sql
session A
BEGIN;
UPDATE t set c =10 where id =0;
update t set c =12 where id = 10;

session B
BEGIN;
UPDATE t set c =11 where id =10
UPDATE t set c =11 where id =0
--1213 - Deadlock found when trying to get lock; try restarting transaction, Time: 0.006000s
```

```pwd

#主要是 死锁自动检测  SHOW VARIABLES LIKE 'innodb_deadlock_detect' 为on 代表是发生死锁自动结束一个线程
但是每次都要检查看有没有和之前的线程造成冲突所以浪费cpu资源
```



### 四 gap  lock record lock 和 next-key lock  

```wiki
1 gap lock () 和record lock 组成 next-key lock 每个 next-key lock 是前开后闭区间( ] 主要是 RR 级别下解决幻读的问题
2 RC 级别下没有 next-key lock 只有record lock 因为没有 gap lock 
3 RR 级别下除 主键 和唯一索引列 是record lock 以外 其他都是有next-key lock 因为要多向右遍历到第一个不满足的值
4 insert intent lock 也是 一种特殊的gap lock

```

### 五 加锁原则

```pwd
在mysql RR隔离级别下
原则 1：加锁的基本单位是 next-key lock。希望你还记得，next-key lock 是前开后闭区间。
原则 2：查找过程中访问到的对象才会加锁。
优化 1：索引上的等值查询，给唯一索引加锁的时候，next-key lock 退化为行锁。
优化 2：索引上的等值查询，向右遍历时且最后一个值不满足等值条件的时候，next-key lock 退化为间隙锁。
一个 bug：唯一索引上的范围查询会访问到不满足条件的第一个值为止。

```

### 六 锁例子

```sql
#DDL
CREATE TABLE `t` (
  `id` int(11) NOT NULL,
  `c` int(11) DEFAULT NULL,
  `d` int(11) DEFAULT NULL,
  `e` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `c_d` (`c`,`d`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
--数据
0	0	0	0
5	5	5	5
10	10	10	10
15	15	15	15
20	20	20	20
25	25	25	25
30	30	30	30

```

```sql
--e 没有索引 锁全表记录 session b 进入等待
BEGIN;
SELECT * from t where e =10 for UPDATE;
BEGIN;
UPDATE t set c =11 where id =20;

--c 有索引 锁记录行 session c 进入等待
BEGIN;
SELECT * from t where c =10 for UPDATE;

BEGIN;
UPDATE t set e =11 where id =20;

BEGIN;
UPDATE t set e =11 where id =10;

-- next-key lock session b 阻塞 索引c 加锁范围是 （5,15) 和 id =10的 record lock

BEGIN;
SELECT * from t where c =10 for UPDATE;

BEGIN;
UPDATE t set c =5 where id =20; --阻塞

UPDATE t set c =15 where id =20;--不阻塞

BEGIN;
UPDATE t set c =4 where id =20; --不会阻塞

BEGIN;
INSERT into t VALUES(12,15,12,12);-- 阻塞

BEGIN;
UPDATE t set c =15 where e=20; -- 阻塞 e 没有索引 全表

BEGIN;
update t set c=15 where id =15; -- 不锁
BEGIN;
update t set c =5 where id =15; --锁


```

```pwd
# 第1和第4为什么会阻塞 这是个问题？
加锁范围是 索引c列（5.15）但是对应数据记录是id =5 到id =15的之间 也就是说 更新的值在这个区间的话要被阻塞
根据 c 排序 1和4 都在 记录id =5 和id =15之间

```



### 六 乐观锁 和悲观锁

```pwd
1 乐观锁：认为并发是少几率的发生，不采用数据库自身锁机制，从程序上控制数据的最终结果 例如加个 version 字段区数据的最新版本号 或者是时间戳 第一次读的时候，会获取 version 字段的取值。然后对数据进行更新或删除操作时，会执行 UPDATE ... SET version=version+1 WHERE version=version 。此时如果已经有事务对这条数据进行了更改，修改就不会成功。

2 悲观锁 ：从数据库自身的锁机制来实现 保证数据的排他性 例如加 读锁（lock in share mode）写锁（for update）。

3 优点
 乐观锁适合读操作多的场景，相对来说写的操作比较少。它的优点在于程序实现，不存在死锁问题，不过适用场景也会相对乐观，因为它阻止不了除了程序以外的数据库操作。
 悲观锁适合写操作多的场景，因为写的操作具有排它性。采用悲观锁的方式，可以在数据库层面阻止其他事务对该数据的操作权限，防止读 - 写和写 - 写的冲突。 


```







