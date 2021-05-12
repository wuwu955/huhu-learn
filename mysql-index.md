

## 一 mysql -index 

### 1.索引是什么

```tex
索引是一种数据结构
对于数据库的表而言，索引其实就是它的“目录”
提高数据检索效率，排序，唯一性，分组，连表join 
缺点 消耗数据库物理存储空间 更新数据 更新索引 性能降低
```



### 2.常见的索引模型

```*
哈希表 (key -value)
 把值放在数组里，用一个哈希函数把 key 换算成一个确定的位置，然后把 value 放在数组的这个位置。多个 key 值经过   哈希函数的换算，会出现同一个值的情况。处理这种情况的一种方法是，拉出一个链表。因为要计算hash值 然后遍历链表 或者是范围查询 都要遍历整个数据 所以哈希表适合等值查询的场景。

有序数组
   在等值查询和范围查询场景中的性能就都非常优秀 但是，在需要更新数据的时候就麻烦了，你往中间插入
 一个记录就必须得挪动后面所有的记录，成本太高。

搜索树
   二叉搜索树的特点是：每个节点的左儿子小于父节点，父节点又小于右儿子。这个时间复杂度是 O(log(N))。n 叉树 以 InnoDB 的一个整数字段索引为例，这个 N 差不多是 1200。这棵树高是 4 的时候，就可以存 1200 的 3 次方个值，这已经 17 亿了。
考虑到树根的数据块总是在内存中的，一个 10 亿行的表上一个整数字段的索引，查找一个值最多只需要访问 3 次磁盘。其实，树的第二层也有很大概率在内存中，那么访问磁盘的平均次数就更少了。
这里解释一下：
O(1) 表示一次操作即可直接取得目标元素（比如字典或哈希表）
O(n) 意味着先要检查 n 个元素来搜索目标 （遍历算法）
O(log n) 二分查找
O(log(n))( B+tree)
```



### 3.innodb 索引模型

```tex
 因为二叉树随着树的深度上升 查询时间变慢 ,B 树的出现就是为了解决这个问题，B 树的英文是 Balance Tree，也就是平衡的多路搜索树，它的高度远小于平衡二叉树的高度
 B 树的主要特点是
  1.一个节点可以拥有多于2个子节点的多叉查找树
  2.适合文件系统和数据库系统
  3.所有叶子节点都在同一层，叶子节点不包含任何健值信息
  4.每个中间节点包含 k-1个关键字和 k个孩子，k 的取值范围为 [ceil(M/2), M] M为总阶层。就是说 关键字2个那么子节点是3个，3个 那么子节点是4个
  
 如图1 为b 树结构 然后我们来看下如何用 B 树进行查找。假设我们想要查找的关键字是 9，那么步骤可以分为以下几步：
   1.我们与根节点的关键字 (17，35）进行比较，9 小于 17 那么得到指针 P1；
   2.按照指针 P1 找到磁盘块 2，关键字为（8，12），因为 9 在 8 和 12 之间，所以我们得到指针 P2；
   3.按照指针 P2 找到磁盘块 6，关键字为（9，10），然后我们找到了关键字 9。
 总结来说 需要中序遍历。
 
 B+ 树 如图二 三
   每一个索引在 InnoDB 里面对应一棵 B+ 树。 主键索引的叶子节点存的是整行数据。在 InnoDB 里，主键索引也被称为聚簇索引（clustered index）。非主键索引的叶子节点内容是主键的值。在 InnoDB 里，非主键索引也被称为二级索（secondary index）。如果语句是 select * from T where ID=500，即主键查询方式，则只需要搜索 ID 这棵 B+ 树；如果语句是 select * from T where k=5，即普通索引查询方式，则需要先搜索 k 索引树，得到 ID 的值为 500，再到 ID 索引树搜索一次。这个过程称为回表。
B+ 树 特点
   1.有 k 个孩子的节点就有 k 个关键字。也就是孩子数量 = 关键字数，而 B 树中，孩子数量 = 关键字数 +1。(重点)
   2.非叶子节点的关键字也会同时存在在子节点中，并且是在子节点中所有关键字的最大（或最小）。
   3.非叶子节点仅用于索引，不保存数据记录，跟记录有关的信息都放在叶子节点中。而 B 树中，非叶子节点既保存索引，也保存数据记录。（重点区别）
   4.所有关键字都在叶子节点出现，叶子节点构成一个有序链表，而且叶子节点本身按照关键字的大小从小到大顺序链接。

B+ 树 对比B 树优势
   B+ 树查询效率更稳定。因为 B+ 树每次只有访问到叶子节点才能找到对应的数据，而在 B 树中，非叶子节点也会存储数据，这样就会造成查询效率不稳定的情况，有时候访问到了非叶子节点就可以找到关键字，而有时需要访问到叶子节点才能找到关键字。
   B+ 树的查询效率更高，这是因为通常 B+ 树比 B 树更矮胖（阶数更大，深度更低），查询所需要的磁盘 I/O 也会更少。同样的磁盘页大小，B+ 树可以存储更多的节点关键字。查询出来的也是比B树多
   在查询范围上，B+ 树的效率也比 B 树高。这是因为所有关键字都出现在 B+ 树的叶子节点中，并通过有序链表进行了链接。而在 B 树中则需要通过中序遍历才能完成查询范围的查找，效率要低很多。看B 树的数据结构知道了 叶子节点没有用双向链表串连

B+ 数 节点数据计算
	大概计算一下：
  (1)局部性原理，将一个节点的大小设为一页，一页4K，假设一个Key有8字节，一个节点可以存储500个Key，即j=500
  (2)m叉树，大概 m/2<= j <=m，即可以差不多是1000叉树
  (3)那么：
  一层树：1个节点，1*500个Key，大小4K
  二层树：1000个节点，1000*500=50W个Key，大小1000*4K=4M
  三层树：1000*1000个节点，1000*1000*500=5亿个Key，大小1000*1000*4K=4G


```

![b tree](https://static001.geekbang.org/resource/image/18/44/18031c20f9a4be3e858743ed99f3c144.jpg)



![b+tree1](https://static001.geekbang.org/resource/image/dc/8d/dcda101051f28502bd5c4402b292e38d.png)

![b+tree](https://static001.geekbang.org/resource/image/55/32/551171d94a69fbbfc00889f8b1f45932.jpg)

### 4.B + 树 对比 hash 索引

```pwd

上面已经有说过 hash 索引模型 这里不多说了 直接贴对比
1.Hash 索引不能进行范围查询，而 B+ 树可以。这是因为 Hash 索引指向的数据是无序的，而 B+ 树的叶子节点是个有序的链表。
2.Hash 索引不支持联合索引的最左侧原则（即联合索引的部分索引无法使用），而 B+ 树可以。对于联合索引来说，Hash 索引在计算 Hash 值的时候是将索引键合并后再一起计算 Hash 值，所以不会针对每个索引单独计算 Hash 值。因此如果用到联合索引的一个或者几个索引时，联合索引无法被利用。
3.Hash 索引不支持 ORDER BY 排序和group by，因为 Hash 索引指向的数据是无序的，因此无法起到排序优化的作用，而 B+ 树索引数据是有序的，可以起到对该字段 ORDER BY 排序优化的作用。同理，我们也无法用 Hash 索引进行模糊查询，而 B+ 树使用 LIKE 进行模糊查询的时候，LIKE 后面前模糊查询（比如 % 开头）的话就可以起到优化作用。
4.Hash 索引存储重复的比较高的列值 容易发生hash 碰撞 导致 （桶中）链表过长的话 查询时遍历链表也是比较耗时
5.Hash 适合等值查询的情况 时间复杂度 O（1）
6 innodb 引擎不支持hash索引 但是支持自适应hash 索引(Adaptive Hash Index) 如果某个数据经常被访问，当满足一定条件的时候，就会将这个数据页的地址存放到 Hash 表中。这样下次查询的时候，就可以直接找到这个页面的所在位置。
需要说明的是自适应 Hash 索引只保存热数据（经常被使用到的数据），并非全表数据。因此数据量并不会很大，因此自适应 Hash 也是存放到缓冲池中，这样也进一步提升了查找效率。
show variables like '%adaptive_hash_index';

```

### 5.数据库存储结构

```tex
在数据库中，不论读一行，还是读多行，都是将这些行所在的页进行加载。也就是说，数据库管理存储空间的基本单位（Page）。
此外 还有 表空间（tablespace），段(Segment),区（Extent）关系如下图 简单的说是 表空间里有段 段下有区 区下有页 页下面是 数据行（row）
```

![storage](https://static001.geekbang.org/resource/image/11/b7/112d7669450e3968e63e9de524ab13b7.jpg)

### 6 数据页结构图

```markdown
简单的说 分三部分
1.首先是文件通用部分，也就是文件头和文件尾。它们类似集装箱，将页的内容进行封装，通过文件头和文件尾校验的方式来确保页的传输是完整的。
2.第二个部分是记录部分，页的主要作用是存储记录，所以“最小和最大记录”和“用户记录”部分占了页结构的主要空间.
3.第三部分是索引部分，这部分重点指的是页目录，它起到了记录的索引作用，因为在页中，记录是以单向链表的形式进行存储的。单向链表的特点就是插入、删除非常方便，但是检索效率不高，最差的情况下需要遍历链表上的所有节点才能完成检索，因此在页目录中提供了二分查找的方式，用来提高记录的检索效率.
```





![storage](https://static001.geekbang.org/resource/image/94/53/9490bd9641f6a9be208a6d6b2d1b1353.jpg)

### 7.B+ 树 是如何进行记录检索的

```wiki
如果通过 B+ 树的索引查询行记录，首先是从 B+ 树的根开始，逐层检索，直到找到叶子节点，也就是找到对应的数据页为止，将数据页加载到内存中，页目录中的槽（slot）采用二分查找的方式先找到一个粗略的记录分组，然后再在分组中通过链表遍历的方式查找记录。
简单的说 因为是叶子节点存储数据 所以查询的时候都是从根节点检索的根据关键字（非叶子节点）然后找到叶子节点 的数据页
加载进内存 在到内存中进行二分查找数据 这里因为叶子节点的数据也是单向链表连接的对应的也是生成了检索目录(这里也是二分查找)
这里补充一下，每个节点就是一个页，在叶子节点中就是一个页 页里的数据按顺序排好 对应生成页目录来检索 所以 查询比较快
这里说一下时间复杂度的 流程 
对页里查找记录时，可先根据二分查找法，先找到记录所有在槽，时间复杂度为O(log2n)。槽内有多条记录，再遍历所有记录，直到找到指定记录为止，时间复杂度为O(n)。这里是在内存中查找了 所以效率还是挺高的
```



### 8. 聚集索引 **clustered index** 

```wiki
1.聚集索引是一种索引，健值逻辑顺序决定了表数据行的物理顺序 例如ID
2.每张表只能建一个聚集索引（tokuDb除外），聚集索引中存储的是整行记录数据
3.没有主健的取第一个非空唯一的列为聚集索引
4.innodb中主键一定是聚集索引，但是聚集索引不一定是主键
```

### 9.联合索引

```wiki
1.多列组成，适合where 条件中的组合
2.可以做到索引覆盖的效果 避免回表 （using index)
3.mysql 不支持多列不同排序规则
例如: SELECT * from t ORDER BY c,d,e desc;
而且排序的话  SELECT * from t ORDER BY d,c,e;也是导致索引失效 变成filesort 因为排序顺序不能调整
说一下 两个独立索引一个 查询 一个排序 只能用一个
4 索引下推 (index condition pushdown ) icp  就是可以在索引遍历过程中，对索引中包含的字段先做判断，直接过滤掉不满足条件的记录，减少回表次数。
列子：select * from t where c >10 and d=12 ; 这里注意的是 d 也是索引中的字段

```

### 10.索引 key_len 技术方法

```wiki
图片出不来....规则
1.正常的 等于索引列字节长度
2.字符串类型的需要同时考虑字符集的因素（utf-8 3 utfmb4 4）
3.允许为 null 的再加 1 
4.变长类型的varchar 再加2
5.只计算利用索引完成数据过滤时的索引长度 ，不包括 group by 和order by 的索引

列子
1. varchar(10) not null UTF-8;   key_len=3*10+2 =32
2. int(11) ; key_len =4+1=5;
3. SELECT * from t WHERE c = 15 and d=15  and e=15 ;  key_len=15
4.SELECT * from t WHERE c = 15 and d=15  ORDER BY e ; key_len=10
5 key_len 的长度不要超过768
```

### 11.唯一索引和普通索引的选择

```wiki
查询效率上 都是读取页到内存 在内存里进行判断 查找，存在普通索引找到数据之后还继续向后查找的记录正好是下一页的数据的情况 这个情况查询效率也是挺快的（唯一索引是找到了就停止了）
插入情况下 这里说一下change buffer 和 innodb_buffer_pool  change buffer 数据的更新修改都是暂时存放在change buffer 里的 查询数据页和后台程序Marge。这样做是适应写多读少的场景 例如帐单 日志类系统
唯一索引 更新内存数据 如果数据存在内存中和普通索引更新没有什么区别 多了个判断而已 如果不存在change buffer 中那么还要重新读取磁盘数据到内存中 这个中间涉及到 随机i/o 性能减少，而普通索引就直接更新在change buffer 中 减少的磁盘的 写 i/o 
但是 在写多读多的场景中 change buffer 就会没有什么作用 因为 更新change buffer 立即访问 会触发 读取磁盘数据和内存中的数据 Marge 加大了 change buffer 的维护成本
如果所有的更新后面，都马上伴随着对这个记录的查询，那么你应该关闭 change buffer。而在其他情况下，change buffer 都能提升更新性能。
所以 综合考虑是 建普通索引好点 唯一索引 不要太多

change buffer 和redo log  都是把数据写入磁盘 但是redo log 和bin_log 确保数据的不可丢


```

### 12 count(*)  count（1）count(filed) 查询效率

```pwd
1 MyISAM 引擎把一个表的总行数存在了磁盘上，因此执行 count(*) 的时候会直接返回这个数，效率很高；
而 InnoDB 引擎就麻烦了，它执行 count(*) 的时候，需要把数据一行一行地从引擎里面读出来，然后累积计数。
2 另外在InnoDB引擎中，如果是采用COUNT(*)和COUNT(1)来统计数据行数，要尽量采用二级索引。
因为主键采用的索引是聚簇索引，聚簇索引包含的信息多，明显会大于二级索引（非聚簇索引）。
如果有多个二级索引的时候，会使用key_len小的二级索引进行扫描。当没有二级索引的时候，才会采用主键索引来进行统计。
3 所以结论是：按照效率排序的话，count(字段)<count(主键 id)<count(1)≈count(*)，所以我建议你，尽量使用 count(*)。主要是count（*）做了优化

```

### 13 distinct 和 group by 的性能

```pwd
没有了 count(*) 以后，也就是不再需要执行“计算总数”的逻辑时，第一条语句的逻辑就变成是：按照字段 a 做分组，相同的 a 的值只返回一行。而这就是 distinct 的语义，所以不需要执行聚合函数时，distinct 和 group by 这两条语句的语义和执行流程是相同的，因此执行性能也相同。
```

### 14 MyISACM 和InnoDB 索引区别 (有趣)

```pwd
MyISACM 其主键索引与普通索引没有本质差异：
  有连续聚集的区域单独存储行记录
  主键索引的叶子节点，存储主键，与对应行记录的指针
  普通索引的叶子结点，存储索引列，与对应行记录的指针
  这里主要是说都是根据 对应的记录指针来找到记录 所以可以没有主键的
InnoDB的主键索引与行记录是存储在一起的，故叫做聚集索引（Clustered Index）：
  没有单独区域存储行记录
  主键索引的叶子节点，存储主键，与对应行记录（而不是指针）
  普通索引非叶子节点存的是key 叶子节点存的是主键id 

```
### 15 InnoDB 表 没有主键索引的采用默认row_id 的坏处

```pwd
   1 采用全局的row_id的话如果表实列过多都去申请全局ID 会造成锁竞争和锁等待
   2 此外也可能会造成主从复制环境下，从库上relay log回放时可能会因为数据扫描机制的问题造成严重的复制延迟问题。
  优化
   每个表都要有显式主键，最好是自增整型，且没有业务用途 
   无论是主键索引，还是辅助索引，都尽可能选择数据类型较小的列
   定义辅助索引时，没必要显式加上主键索引列（针对MySQL 5.6之后）
   行数据越短越好，如果每个列都是固定长的则更好（不是像VARCHAR这样的可变长度类型）
```
### 16 InnoDB 内部内存淘汰策略 lru

```pwd
 流程
  1 扫描过程中，需要新插入的数据页，都被放到 old 区域 
  2 一个数据页里面有多条记录，这个数据页会被多次访问到，但由于是顺序扫描，这个数据页第一次被访问和最后一次被访问的时间间隔不会超过 1 秒
  ，因此还是会被保留在 old 区域
  3 再继续扫描后续的数据，之前的这个数据页之后也不会再被访问到，于是始终没有机会移到链表头部（也就是 young 区域），很快就会被淘汰出去
  4 基于链表的数据结构 young：old =5:3
 对于全表查询的sql 来说 mysql 采用的是边读边发的逻辑 如果客户端读取较慢 那就服务端发送不出去 造成长事物（sening to client 服务器端的网络栈写满了）但是不打爆内存
 其次是 buffer pool 内存淘汰机制

```
### 17 join 中的 Index Nested-Loop Join 和 Block Nested-Loop Join 

```pwd
  Index Nested-Loop 就是驱动表使用了索引扫描 
  Block Nested-Loop Join  是没有使用到索引  把数据分块放入内存（join buffer）中然后在遍历被动表 因为在内存中比较 有点快
  推荐驱动表选择小表（返回数据少，字段总长度少）
问题 如果被驱动表是一个大表，并且是一个冷数据表，除了查询过程中可能会导致 IO 压力大以外，你觉得对这个 MySQL 服务还有什么更严重的影响吗？
 1. 长期占用DML锁，引发DDL拿不到锁堵慢连接池；
 2. SQL执行socket_timeout超时后业务接口重复发起，导致实例IO负载上升出现雪崩；
 3. 实例异常后，DBA kill SQL因繁杂的回滚执行时间过长，不能快速恢复可用；
 4. 如果业务采用select *作为结果集返回，极大可能出现网络拥堵，整体拖慢服务端的处理；
 5. 冷数据污染buffer pool，block nested-loop多次扫描，其中间隔很有可能超过1s，从而污染到lru 头部，影响整体的查询体验。
 6. join_buffer 不够大，需要对被驱动表做多次全表扫描，也就造成了“长事务”。
 7. 导致undo log 不能被回收，导致回滚段空间膨胀问题

```
### 18 为什么 索引字段 where xx is null 使用了索引 is not null 没有使用索引？
```pwd
todo
```

### 19 索引下推现象 ICP 
```pwd

1 表t 独立索引 id ,c 
EXPLAIN
SELECT * from t WHERE c =30 and e BETWEEN 10 and 30;
1	SIMPLE	t		ref	c	c	5	const	3	12.50	Using where 

2 表t 独立索引 id ,c ,e 
1	SIMPLE	t		ref	c,e	c	5	const	3	62.50	Using where

3 表t 独立索引 id ,联合索引c_e
1	SIMPLE	t		range	c_e	c_e	10		2	100.00	Using index condition
现象 Using where 还是要回表查询 Using index condition 就不用回 2个独立索引同时出现只能一个有效
 
```
### 20 优化模糊查询 like '%xx%' 

```pwd
1 表t_s 独立索引 id ,city
SELECT id from t_s WHERE city like '%h%'; SELECT city from t_s WHERE city like '%h%';
1	SIMPLE	t_s		index		city	66		2	50.00	Using where; Using index
#Using where; Using index 索引扫描和索引覆盖扫描
SELECT * from t_s WHERE city like '%h%';
1	SIMPLE	t_s		ALL					2	50.00	Using where
下面sql就是没有利用 索引覆盖的特点 所以sql eq_ref 主键索引连表 前提是 like 的字段要建索引 没有索引也就没有主键ID
EXPLAIN
SELECT * from  t_s s INNER JOIN (SELECT id from t_s WHERE city like '%h%') b on s.id=b.id
1	SIMPLE	t_s		index	PRIMARY	city	66		2	50.00	Using where; Using index
1	SIMPLE	s		eq_ref	PRIMARY	PRIMARY	4	learn.t_s.id	1	100.00	

```
### 21  什么情况下没有使用索引？
```pwd
1 like ‘%xx’; 
2 数据类型 出现隐式转换 where id ='1';
3 复合索引 范围查询 或者没有满足最左原则 idx_a_b_c  where b=xx  where a=xx and c=xx;
4 where 条件后 两个独立索引只能用一个   idx_a, idx_b  where a=x and b=xx; 
5 索引值重复度太高 全表扫描比索引扫描要快
6 用or 分开的条件 如果前面的条件列有索引 后面的没有 那么都不会用到  idx_a, where a=xx or b =xx;
这里是说后面的or 要走全表扫描那么我直接一直全表扫描算了 不用再去扫索引减少io
7 多表join 的时候 join的列值字符集不相同也是用不到  on e.name(utf-8)=b.name(gbk);
8 多字段排序时字段排序规则不同  order by xx desc ,bb asc; 

#查看索引情况理不想
show status like 'handler_read%' ;
Handler_read_key 值比较高的话就说明一个行被索引的次数
Handler_read_rnd_next 值比较高的话就说明 表索引不正确和查询没有使用索引
#优化 方法
1 定期 分析表和检查表   analyze table xx; check table xx;
2 优化表  optimize table xx; 整理表空间合并碎片
innobd 设置 独立表空间 innodb_file_per_table 参数后每个表生成一个.db 文件 可以通过 alter table xx engine =innodb;
3 这些都是在系统不忙的时候来操作

```
### 22 order by 出现file sort？
```pwd
索引 id idx_c_e
1 SELECT * from t where c=10 ORDER BY c
1	SIMPLE	t		ref	c_e	c_e	5	const	1	100.00	
2 SELECT * from t where c=10 ORDER BY id
1	SIMPLE	t		ref	c_e	c_e	5	const	1	100.00	Using index condition; Using filesort
3 SELECT * from t ORDER BY c desc ,e 
1	SIMPLE	t		ALL					8	100.00	Using filesort
优化 加大 sort_buffer_size 值
加 联合索引 看25个案例
```
### 23 group by 没有order by 也会 出现file sort？
```pwd
d没有索引 有索引虽然没有文件排序但是也是走了索引排序了
SELECT d,COUNT(*) from t GROUP BY d  没有显示加order by 就有排序的
1	SIMPLE	t		ALL					8	100.00	Using temporary; Using filesort
加上 order by null 禁止排序
explain
SELECT d,COUNT(*) from t GROUP BY d ORDER BY null;
1	SIMPLE	t		ALL					8	100.00	Using temporary

```
### 24 更新语句流程
```pwd
#更新数据流程
1 更新内存值 buffer pool
2 记录redo log 先做 prepare 等待 bin log commit 
3 bin log commit 
4 redo log commit 
```

### 25 where 语句后 order by 和group  by  出现file sort？
```pwd
#sql
SELECT * FROM `t_account` WHERE name ='娃哈哈' ORDER BY phone;
创建 单独索引name 和phone 只能用到name一个索引 出现file sort情况
原因 order by和group  by 是基于最左匹配原则 
所以 这里要建立联合索引来避免出现file sort

ALTER table t_account add index idx_name_phone_gender(name,phone,gender)
explain
SELECT * FROM `t_account` WHERE name ='娃哈哈' ORDER BY phone;
condition
```




