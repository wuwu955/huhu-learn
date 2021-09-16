## 记录工作中用到的sql 和函数以及原理知识

### 1 把列为null的转换成其他值

```sql
 select coalesce(comm,0)from  xx;

#字符串替换函数
 REPLACE(str,from_str,to_str)

#排序时对Null值的处理 使用case when 函数
 SELECT ename,sal,comm FROM (SELECT ename,sal,comm,CASE WHEN comm IS NULL THEN 0 ELSE 1 END AS is_null FROM emp) x ORDER BY is_null desc,comm;
 #以及动态排序
order by case when job = 'SALESMAN' then comm else sal end
# union all 只要是字段类型和字段数目相同就可以 合并 注意不能使用limit
#使用in or not in 时注意null 值 尽量用 exists 来代替
SELECT b.id,b.shop_name, b.shop_code, b.province_code, b.city_code, b.country_code , b.detail_address,
  b.shop_weight, p.park_type, p.park_scale, p.decoration_degree,p.in_shop
  FROM shop_industrial_park p INNER JOIN shop_base b ON p.shop_code = b.shop_code
  WHERE NOT EXISTS ( SELECT u.shop_code FROM shop_audit u WHERE p.shop_code = u.shop_code AND u.audit_status = 4 )
```

###  2 行转列sql

```sql
#jsh_functions 这个是ID自增表 可以取其他的
select a.id,substring_index(substring_index(a.col,',',b.id),',',-1) as person_id
        from
        (select `Salesman` as col,id from jsh_depothead  ) as a
        join
        jsh_functions as b
 on b.id < (char_length(a.col) - char_length(replace(a.col,',',''))+1)+1

# 补充生成自增序号 序号生成最好是采取拼接字符串里的id 是哪个表就哪个表来做 
 select a.work_id,substring_index(substring_index(TRIM(BOTH ',' FROM a.col),',',b.row_number),',',-1) as user_id
        from
        (select `owner_user_id` as col,work_id  from 72crm_work ) as a
        join
        (select (@ROW:=@ROW+1) row_number from 72crm_admin_user a,(SELECT @ROW:=0) r) as b
 on b.row_number < (char_length(TRIM(BOTH ',' FROM a.col)) - char_length(replace(TRIM(BOTH ',' FROM a.col),',',''))+1)+1
 WHERE a.work_id =7


```

### 3 获取字符串中的大写字母

```sql

CREATE FUNCTION `Fun_GetPY`(in_string VARCHAR(16000)) RETURNS varchar(16000) CHARSET utf8
BEGIN
#截取字符串，每次做截取后的字符串存放在该变量中，初始为函数参数in_string值
DECLARE tmp_str VARCHAR(16000) CHARSET utf8 DEFAULT '' ; 
#tmp_str的长度
DECLARE tmp_len SMALLINT DEFAULT 0;
#tmp_str的长度
DECLARE tmp_loc SMALLINT DEFAULT 0;
#截取字符，每次 left(tmp_str,1) 返回值存放在该变量中
DECLARE tmp_char VARCHAR(2) CHARSET utf8 DEFAULT '';
#结果字符串
DECLARE tmp_rs VARCHAR(16000)CHARSET utf8 DEFAULT '';
#拼音字符，存放单个汉字对应的拼音首字符
DECLARE tmp_cc VARCHAR(2) CHARSET utf8 DEFAULT '';
#初始化，将in_string赋给tmp_str
SET tmp_str = in_string;
#初始化长度
SET tmp_len = LENGTH(tmp_str);
#如果被计算的tmp_str长度大于0则进入该while
WHILE tmp_len > 0 DO 
#获取tmp_str最左端的首个字符，注意这里是获取首个字符，该字符可能是汉字，也可能不是。
SET tmp_char = LEFT(tmp_str,1);
#左端首个字符赋值给拼音字符
SET tmp_cc = tmp_char;
#获取字符的编码范围的位置，为了确认汉字拼音首字母是那一个
SET tmp_loc=INTERVAL(CONV(HEX(tmp_char),16,10),0xB0A1,0xB0C5,0xB2C1,0xB4EE,0xB6EA,0xB7A2,0xB8C1,0xB9FE,0xBBF7,0xBFA6,0xC0AC
,0xC2E8,0xC4C3,0xC5B6,0xC5BE,0xC6DA,0xC8BB,0xC8F6,0xCBFA,0xCDDA ,0xCEF4,0xD1B9,0xD4D1);
#判断左端首个字符是多字节还是单字节字符，要是多字节则认为是汉字且作以下拼音获取，要是单字节则不处理。如果是多字节字符但是不在对应的编码范围之内，即对应的不是大写字母则也不做处理，这样数字或者特殊字符就保持原样了
IF (LENGTH(tmp_char)>1 AND tmp_loc>0 AND tmp_loc<24) THEN
#获得汉字拼音首字符
SELECT ELT(tmp_loc,'A','B','C','D','E','F','G','H','J','K','L','M','N','O','P','Q','R','S','T','W','X','Y','Z') INTO tmp_cc; 
END IF;
IF ASCII(tmp_cc)>64 AND ASCII(tmp_cc) <91
THEN
#将当前tmp_str左端首个字符拼音首字符与返回字符串拼接
SET tmp_rs = CONCAT(tmp_rs,tmp_cc);
END IF;
#将tmp_str左端首字符去除
SET tmp_str = SUBSTRING(tmp_str,2);
#计算当前字符串长度
SET tmp_len = LENGTH(tmp_str);
END WHILE;
#返回结果字符串
RETURN tmp_rs;
END

```
###  4 取模函数
```sql
#跳过一行进行取数据 
SELECT  * from 72crm_crm_leads WHERE mod(leads_id,2)=1


```
### 5 基础知识
```pwd
DDL 数据库定义语言  修改表结构 alter 
DML 数据库操作语言  对数据库数据操作的 inster 
DCL 数据库访问级别 权限 grant
Having 和where 的区别在于 where 在聚合函数之前过滤数据 having 是在之后过滤数据
group by与with rollup 是对聚合函数之后的数据在汇总 相当于 是对每列在汇总
int(2) 这里的2 代表宽度但是超过这个宽度也没有影响 宽度一般配合 zreofill 来使用 不足的用0 来填充

#浮点数和定点数 尽量用浮点数 decimal
小数 表示 单精度 float 双精度 double 定点 decimal(m,d)m 精度 d 标度 超出报错 但是 其他的超出截取掉
varchar char 代表字符长度 字节看编码集下的字节数 
#字符串函数
把指定的位置的字符串换成其他字符串
INSERT(str,pos,len,newstr) 
保留几位小数
TRUNCATE(money,1) 

#视图
create or replace view xx_view as select * from table  创建视图 注意from 后面不能跟子查询
注意 以下的视图是不能更新的
含有关键字 聚合函数sum() max(),distinct,group by ,having ,union union all (order by 是可以的)
 ex:  select * from table group by 
常量视图 select 中包含子查询
ex: select 111 as contans  ,select (select * from xx )
其他可以更新视图 然后表数据也同步了
获取 表结果定义和视图
SHOW create table t;  SHOW create view  t_view;
with local 只要有视图满足条件就更新
with cascaded 所有视图都要满足条件才能更新

# 存储过程和存储函数 
https://www.runoob.com/w3cnote/mysql-stored-procedure.html
先编译 直接调用数据库存储引擎接口 减少网络传输开销 效率高
存储过程和存储函数的区别是 看参数和返回值 存储函数 参数必须是in 和必须有返回值 而存储过程 参数可以是 in,out,inout 类型 没有返回值
创建 存储过程 和存储函数
create procedure 存储过程名(参数)
ex CREATE PROCEDURE `get_max_hero`(in roleName VARCHAR(50),OUT hpMax FLOAT)
BEGIN
SELECT MAX(hp_max) from heros WHERE role_main = roleName INTO hpMax;
end
调用 call get_max_hero('xx');
create function 存储函数名(参数)

#定时事件任务器 event 和触发器 trigger 
定义 一个每5秒修改值的事件
create EVENT xx_event on schedule every 5 SECOND
do UPDATE t set c =c+1 WHERE id =5;
查看 事件的状态 和是否开启
show EVENTS;
show VARIABLES like '%schedule%'; //off 为关 0 
set GLOBAL event_scheduler =1;//开启
禁用和删除 事件
alter event xx_event disable;
drop evnet xx_event;
触发器 查看相关资料了解一下 不推荐 使用

#分区 partition  https://dev.mysql.com/doc/refman/5.7/en/partitioning-overview.html
创建分区
ex: CREATE TABLE members (
    firstname VARCHAR(25) NOT NULL,
    lastname VARCHAR(25) NOT NULL,
    username VARCHAR(16) NOT NULL,
    email VARCHAR(35),
    joined DATE NOT NULL
)
PARTITION BY KEY(joined)
PARTITIONS 6;

CREATE TABLE members (
    firstname VARCHAR(25) NOT NULL,
    lastname VARCHAR(25) NOT NULL,
    username VARCHAR(16) NOT NULL,
    email VARCHAR(35),
    joined DATE NOT NULL
)
PARTITION BY RANGE( YEAR(joined) ) (
    PARTITION p0 VALUES LESS THAN (1960),
    PARTITION p1 VALUES LESS THAN (1970),
    PARTITION p2 VALUES LESS THAN (1980),
    PARTITION p3 VALUES LESS THAN (1990),
    PARTITION p4 VALUES LESS THAN MAXVALUE
);
1 好处 对表字段的值进行按值类型分区 优化查询 where  sum 和count 查询和平行计算 删除数据 通过删除分区就比delete 快
2 查看是否支持分区 show plugins ；看到 partition 就可以了
3 注意点 同一个分区使用同一个引擎 还有 要么分区表包含主健 要么就不包含
4 分区类型 看这里分区表下同时索引 查询效率比较 https://blog.csdn.net/zhanaolu4821/article/details/100187231
Range 根据列值在给定范围内将行分配给分区 使用 VALUES LESS THAN (1960),
List 类似于通过进行分区RANGE，不同之处在于，根据匹配一组离散值之一的列选择分区
hash  将根据由用户定义的表达式返回的值来选择一个分区，该表达式将对要插入表中的行中的列值进行操作
key  
columns  多个列分区  SELECT (1,10)<(10,10)from DUAL; 判断数据在哪分区可以这样0 false 1 true

```

###  6 sql 优化
```sql
#查看数据库 查询和插入次数
show status like 'Com%' ;
#查看索引的使用情况 desc /explain
看 type 类型  
all 全表扫描  index 全索引扫描 range 索引范围扫描 between and > < ref 普通索引扫描或者是 唯一索引前缀扫描
表join 中等值条件也是普通索引的 eq_ref 使用唯一索引或者是 主键 查询和join的sql  const/system 和 eq_ref 差不多都是比较迅速

#EXTENDED 查看优化器对sql 做了什么 改变 EXTENDED 在之后的版本将会移除 结合 下面的warring 来用
explain EXTENDED SELECT count(*) from t WHERE c=10;
show WARNINGS;
#查看sql 访问的是哪个分区
explain PARTITION SELECT * from t WHERE c=10;
#查看是否开启 profile yes 开启 
SELECT @@have_profiling;
SELECT @@profiling; 
set profiling =1;
#查看所有sql查询ID
show PROFILES ;
#根据ID 查询具体耗时操作
show PROFILE for QUERY 390;


#找到sql 查询进程
show PROFILES ;
#设置进程 根据步骤分组和时间排序
set @query_id:=556;
SELECT state ,sum(DURATION) as total_r,
ROUND( 100*sum(DURATION)/(SELECT sum(DURATION) from information_schema.profiling WHERE QUERY_ID =@query_id)
,2) as pct_r,
COUNT(*) as calls,
sum(DURATION)/COUNT(*) as 'r/call'
from information_schema.profiling WHERE QUERY_ID =@query_id
GROUP BY STATE
ORDER BY total_r desc;

#查看sql在cpu 上的消耗
show PROFILE cpu for QUERY @query_id;

#通过trace 分析优化器如何生成执行计划
#查看 跟踪器是否打开  enabled=off,one_line=off
show VARIABLES like 'optimizer%';
#开启和设置最大数量 optimizer_trace_max_mem_size
set optimizer_trace='enabled=on';
set optimizer_trace_max_mem_size=1000000;
/* @a保存Innodb_rows_read的初始值 */
select VARIABLE_VALUE into @a from performance_schema.session_status where variable_name = 'Innodb_rows_read';
/* 执行语句 */
select city, name,age from t where city='杭州' order by name limit 1000;
/* 查看 OPTIMIZER_TRACE 输出 这个要在命宁行才能看到trace 信息*/
SELECT * FROM `information_schema`.`OPTIMIZER_TRACE`;
/* @b保存Innodb_rows_read的当前值 */
select VARIABLE_VALUE into @b from performance_schema.session_status where variable_name = 'Innodb_rows_read';
/* 计算Innodb_rows_read差值 */
select @b-@a;

"filesort_summary":{
    "rows": 0,
    "examined_rows": 0,
    "number_of_tmp_files": 0,
    "sort_buffer_size": 190264,
    "sort_mode": "<sort_key, packed_additional_fields>"
}
number_of_tmp_files:排序过程中使用的临时文件数 看 mysql 45 16讲
看索引有没有被优化器使用 主要看 trace 中 table_scan 的 rows 和 cost 对比 索引扫描 rows和cost 值的大小 

```
###  7 用bit_or（）或者bit_and（） 统计客户购买的商品信息
```sql
在线 二进制 转换 https://tool.lu/hexconvert/
用二进制数所在位来表示商品（从右到左） 1 面包 2 牛奶 3 饼干 4 啤酒  0 代表没买 1代表买了 例如 5 二进制 0101 代表 买了牛奶和啤酒
#ddl
CREATE TABLE `order_rab` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `customer_id` int(11) DEFAULT NULL,
  `kind` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4
#那么表数据
1	1	4  //第一次买了 0100 牛奶
2	1	5  // 二次 0101 牛奶和啤酒
3	2	4  // 第一次买了 0100 牛奶
4	2	3  //第二次 0011 买了饼干和啤酒
#统计所有购买的商品
SELECT customer_id ,bit_or(kind) from order_rab GROUP BY customer_id
1	5 //0101 牛奶和啤酒
2	7 //0111 牛奶,饼干和啤酒
#统计每次购买的商品
SELECT customer_id ,bit_and(kind) from order_rab GROUP BY customer_id
1	4 // 0100 牛奶
2	0 // 0000 没有

```

###  8 优化数据表结构和表设计
```sql
1 表结构分析 这个没有什么软用 看看就好 16，255 是去除枚举值的提示
SELECT * from area procedure analyse(16,255);
2 拆分表数据 水平拆分就是一个建立多个相同表结构的表 把数据分散开来  垂直拆分就是 按列来拆分 减少表行数 多表关联
3 反范式设计 建立适合冗余字段 但是表数据修改同步 需要使用 触发器来同步多个表的字段值
4 经常查询计算的值 可以用中间表来先存好计算的值再来查询中间表
```
### 9 锁相关查看方式

```sql

#查看表锁 Table_locks_waited 值高 竞争严重
show status like 'table%';
#查看行锁竞争 Innodb_row_lock_waits Innodb_row_lock_time_avg 高就严重
show status like 'innodb_row_lock%';
#查看 information_schema 表情况 事物 锁线程 和锁等待线程
SELECT * from information_schema.innodb_trx;
SELECT * from information_schema.innodb_locks;
SELECT * from information_schema.innodb_lock_waits;
#查看 innodb 状态 内存 事物 io
show ENGINE INNODB STATUS;
```
### 10 innodb 缓存相关的

```sql

#查看 innodb_buffer_pool_size 缓存大小 默认128m
show VARIABLES like 'innodb_buffer_pool_%';
#缓存分配个数 innodb_buffer_pool_instances 默认1 

#查看 innodb_buffer_pool 使用情况 (1-Innodb_buffer_pool_reads/Innodb_buffer_pool_read_requests) 低则加 缓存值
#Innodb_buffer_pool_wait_free 等待空白页的个数
show STATUS like 'innodb_buffer_pool_%';
#查看 old_sublist 大小 innodb_old_blocks_pct 默认 37
#innodb_old_blocks_time 配置数据存在 old_sublist 的时间超过时间就放进 young_list里 如果 youngs很低就调高
show VARIABLES like 'innodb_old_blocks%';

#控制缓存刷新 延长缓存时间  innodb_max_dirty_pages_pct 脏页比例 默认75 超过就刷盘
show VARIABLES like 'innodb_max%';
# innodb_io_capacity 读写磁盘io 能力 默认200次/s 固态硬盘和多磁盘  可以调大  
show VARIABLES like 'innodb_io%';

#innodb 双写机制（doublewrite）
主要是 innodb 一页数据是16k 但是操作系统是4k 为了保证数据写入的完整性 就先将脏页数据副本保存到 doublewrite buffer  然后fsync()刷盘到系统
表空间 写入后在 把数据写入磁盘 恢复是根据系统表空间的doublewrite buffer 来对应恢复数据
show VARIABLES like 'innodb_double%'; //默认 on 
 
#查看排序合并值 Sort_merge_passes 值大就说要通过 设置 sort_buffer_size 和 join_buffer_size 来改善 group by 和 ORDER BY 的性能 
show STATUS like  'sort%';
show VARIABLES like 'sort_buffer_size%';
show VARIABLES like 'join_buffer_size%';

#redo log 日志文件 大小 innodb_log_file_size
show VARIABLES like 'innodb_log%';

#设置最大连接数 thread_cache_size/max_connections 接近1 说明 线程缓存命中低
show VARIABLES like 'max_connection%';
show VARIABLES like 'thread_cache_size';

#查看引擎的数据大小索引大小
	SELECT  ENGINE,
        ROUND(SUM(data_length) /1024/1024, 1) AS "Data MB",
        ROUND(SUM(index_length)/1024/1024, 1) AS "Index MB",
        ROUND(SUM(data_length + index_length)/1024/1024, 1) AS "Total MB",
        COUNT(*) "Num Tables"
    FROM  INFORMATION_SCHEMA.TABLES
    WHERE  table_schema not in ("information_schema", "PERFORMANCE_SCHEMA", "SYS_SCHEMA", "ndbinfo", "sys")
    GROUP BY  ENGINE;
# 查看对应表数据大小
SELECT
table_name,
CONCAT(FORMAT(SUM(data_length) / 1024 / 1024,2),'M') AS dbdata_size,
CONCAT(FORMAT(SUM(index_length) / 1024 / 1024,2),'M') AS dbindex_size,
CONCAT(FORMAT(SUM(data_length + index_length) / 1024 / 1024 / 1024,2),'G') AS table_size,
AVG_ROW_LENGTH,table_rows,update_time
FROM
information_schema.tables
WHERE table_schema = 'dbName' and table_name='tbName';
#查看磁盘数据大小
du -sh /datas/mysql/data/db/tableName*

 # dba 用的sql
 https://opensource.actionsky.com/20190115-mysql/
```
### 11 打卡学习 第一周 2020 02-24～2020 03-01
```sql

1 优化方法 重新优化表统计信息  analyze table 和强制使用索引 use index 和调整写法加limit 或者重建索引和删除索引
2 学习mysql 给字符串加索引 字符串太长索引比较占空间 可以采用 倒序存储，再创建前缀索引，还可以添加字段存储字符串的hash值 减少索引占用空间
3 学习mysql为什么会抖动 原因是后台进程在刷脏页 而脏页又是内存数据与磁盘数据不一样的内存页称为脏页 脏页又是因为mysql采用WAL技术导致内存数据缓存比较多 如果内存满了就需要阻止数据更新操作 先让脏页覆盖磁盘数据 所以会导致一条更新语句为什么有时会很慢 
对此要看 innodb_io_capacity 参数和脏页比例Innodb_buffer_pool_pages_dirty/Innodb_buffer_pool_pages_total 重点值是不能超过75%
4 直接创建完整索引，这样可能比较占用空间；创建前缀索引，节省空间，但会增加查询扫描次数，并且不能使用覆盖索引；
倒序存储，再创建前缀索引，用于绕过字符串本身前缀的区分度不够的问题；创建 hash 字段索引，查询性能稳定，有额外的存储和计算消耗，跟第三种方式一样，都不支持范围扫描。
5 脏页比例
select VARIABLE_VALUE into @a from global_status where VARIABLE_NAME = 'Innodb_buffer_pool_pages_dirty';
select VARIABLE_VALUE into @b from global_status where VARIABLE_NAME = 'Innodb_buffer_pool_pages_total';
select @a/@b;
6 数据删除了表空间为什么还那么大 因为数据是标记删除的 如果主键ID一致可以复用这块空间不一致的话就会产生数据空洞 还有数据随机插入导致页分裂 修改索引值导致先删除在更新的操作也容易产生数据空洞 那么怎么看数据碎片情况呢 看data_free参数 大了就alter table t engine=innodb  这里还有独立表空间和共享表空间 独立表空间drop 表就会删除.db文件 而共享表空间删除文件但是空间还是不会释放
7 count *统计的问题 业界方案是数据库和redis结合但是容易出现双写不一致的问题 先写数据库 在写Reids redis失败抛异常回滚数据 按道理来说应该可以 Reids单线程。 在就是count*=count1 >count id> count f 
8 实际上，redo log 并没有记录数据页的完整数据，所以它并没有能力自己去更新磁盘数据页，也就不存在“数据最终落盘，是由 redo log 更新过去”的情况。
如果是正常运行的实例的话，数据页被修改以后，跟磁盘的数据页不一致，称为脏页。最终数据落盘，就是把内存中的数据页写盘。这个过程，甚至与 redo log 毫无关系。
在崩溃恢复场景中，InnoDB 如果判断到一个数据页可能在崩溃恢复的时候丢失了更新，就会将它读到内存，然后让 redo log 更新内存内容。更新完成后，内存页变成脏页，就回到了第一种情况的状态。
9 redo log 主要节省的是随机写磁盘的 IO 消耗（转成顺序写），而 change buffer 主要节省的则是随机读磁盘的 IO 消耗。
10 redo log 就是记录更新操作而已便于恢复 数据更新还是在内存中 并没有刷到磁盘 等待Marge 刷盘 其中主要是 1 redo log写满了刷盘 2 系统内存不足了刷盘 3 系统不忙时清理redo log  把内存数据写入磁盘 4 关机重启
11 随机显示拼接s q l
mysql> select count(*) into @C from t;
set @Y = floor(@C * rand());
set @sql = concat("select * from t limit ", @Y, ",1");
prepare stmt from @sql;
execute stmt;
DEALLOCATE prepare stmt;
```

### 12 打卡学习 第二周 2020 03-02～2020 03-08
```sql
1 mysql 索引失效的原因 1 索引字段用函数进行转换 会造成优化器不走索引字段扫描而去走主键id 扫描全表 2 字符串和int类型进行比较也是转换问题 3 表字符集不同 join 字段进行比较的时候也是进行了类型转换 造成索引失效

2 查询为什么会这么慢 1 查询是正好进行表结构修改 会对表进行mdl 的表锁 那么会阻塞所有查询和更新的操作 2 还有就是更新操作上加了锁 然查询加了共享读锁（lock in share mode ）那么造成读写锁冲突 3 还有就是本身的索引失效导致全表扫描
3 幻读是什么 幻读是指一个事务多次执行一条查询返回的值却是不同的值。为啥出现这种情况呢 因为数据读取到内存中 并没有对其加写锁其他事物对其修改 但是当前事物可以读到其他事物修改后的值 行锁只能锁住行，但是新插入记录这个动作，要更新的是记录之间的“间隙”。在 RR级别下加锁也就是间隙锁 (Gap Lock)。 next-key-lock 锁间隙和记录锁 来解决这个问题 
4 select for update 语句，相当于一个 update 语句。在业务繁忙的情况下，如果事务没有及时的commit或者rollback 可能会造成其他事务长时间的等待，从而影响数据库的并发使用效率。
select lock in share mode 语句是一个给查找的数据上一个共享锁（S 锁）的功能，它允许其他的事务也对该数据上 S锁，但是不能够允许对该数据进行修改。如果不及时的commit 或者rollback 也可能会造成大量的事务等待。
for update 和 lock in share mode 的区别：前一个上的是排他锁（X 锁），一旦一个事务获取了这个锁，其他的事务是没法在这些数据上执行 for update ；后一个是共享锁，多个事务可以同时的对相同数据执行 lock in share mode。

5 锁是加在索引上的 如果你要用 lock in share mode 来给行加读锁避免数据被更新的话，就必须得绕过覆盖索引的优化，在查询字段中加入索引中不存在的字段 
6 在利用普通索引删除数据的时候尽量加 limit。这样不仅可以控制删除数据的条数，让操作更安全，还可以减小加锁的范围。

7 SELECT  * from t WHERE c >=15 and c <=20 ORDER BY c desc LOCK in SHARE MODE; next-key-lock 
由于是 order by c desc，第一个要定位的是索引 c 上“最右边的”c=20 的行，所以会加上间隙锁 (20,25) 和 next-key lock (15,20]。在索引 c 上向左遍历，要扫描到 c=10 才停下来，所以 next-key lock 会加到 (5,10]，这正是阻塞 session B 的 insert 语句的原因。在扫描过程中，c=20、c=15、c=10 这三行都存在值，由于是 select *，所以会在主键 id 上加三个行锁。这里 最终没有给10加行锁
索引 c 上 (5, 25)；主键索引上 id=15、20 两个行锁。
8 你在什么时候会把线上生产库设置成“非双 1”。我目前知道的场景，有以下这些：业务高峰期。一般如果有预知的高峰期，DBA 会有预案，把主库设置成“非双 1”。备库延迟，为了让备库尽快赶上主库。 用备份恢复主库的副本，应用 binlog 的过程，这个跟上一种场景类似。批量导入数据的时候。
把生产库改成“非双 1”配置，是设置 innodb_flush_logs_at_trx_commit=2(表示每次事务提交时都只是把 redo log 写到 page cache。)、sync_binlog=1000(sync_binlog=N(N>1) 的时候，表示每次提交事务都 write，但累积 N 个事务后才 fsync)。
9 在 InnoDB 中，innodb_thread_concurrency 这个参数的默认值是 0，表示不限制并发线程数量。但是，不限制并发线程数肯定是不行的。因为，一个机器的 CPU 核数有限，线程全冲进来，上下文切换的成本就会太高。所以，通常情况下，我们建议把 innodb_thread_concurrency 设置为 64~128 之间的值。


```
### 13 not exists 改left join sql
```sql

#left join
SELECT u.* from user_workbench u LEFT JOIN c_accounting_company c on u.id=c.user_workbench_id WHERE MONTH(u.created) =2
and user_workbench_id is null 

1	SIMPLE	u		ALL					136	100.00	Using where
1	SIMPLE	c		ref	idx_workbench_user_id	idx_workbench_user_id	8	gua.u.id	13	100.00	Using where; Not exists; Using index

    # NOT EXISTS
SELECT * from user_workbench u WHERE MONTH(u.created) =2 and NOT EXISTS (SELECT id from  c_accounting_company c WHERE u.id=c.user_workbench_id)

1	PRIMARY	u		ALL					136	100.00	Using where
2	DEPENDENT SUBQUERY	c		ref	idx_workbench_user_id	idx_workbench_user_id	8	gua.u.id	13	100.00	Using index
    
 #把not EXISTS 改写成   left join 主要是查关联ID is  null
 
 
#开启redo_log和binglog的时间监控
update PERFORMANCE_SCHEMA.setup_instruments set ENABLED='YES', Timed='YES' where name like '%wait/io/file/innodb/innodb_log_file%';
update PERFORMANCE_SCHEMA.setup_instruments set ENABLED='YES', Timed='YES' where name like '%wait/io/file/sql/binlog%';


#统计io 超过200毫秒的
SELECT
	event_name,
	MAX_TIMER_WAIT 
FROM
	PERFORMANCE_SCHEMA.file_summary_by_event_name 
WHERE
	event_name IN ( 'wait/io/file/innodb/innodb_log_file', 'wait/io/file/sql/binlog' ) 
	AND MAX_TIMER_WAIT > 200 * 1000000000;
#清空
truncate table performance_schema.file_summary_by_event_name;
	
```


### 14 打卡学习 第三周 2020 03-09 2020 03-15
```sql
1 发送 kill 命令的客户端，并没有强行停止目标线程的执行，而只是设置了个状态，并唤醒对应的线程 而被 kill 的线程，需要执行到判断状态的“埋点”，才会开始进入终止逻辑阶段。并且，终止逻辑本身也是需要耗费时间的。2 在大事务没有提交的同时 对其kill 回滚时间比较大 也是导致kill 不掉

 2 查询很多数据会不会把内存打爆  由于 MySQL 采用的是边算边发的逻辑，因此对于数据量很大的查询结果来说，不会在 server 端保存完整的结果集。所以，如果客户端读结果不及时，会堵住 MySQL 的查询过程，但是不会把内存打爆。
 而对于 InnoDB 引擎内部，由于有淘汰策略，大查询也不会导致内存暴涨。并且，由于 InnoDB 对 LRU 算法做了改进，冷数据的全表扫描，对 Buffer Pool 的影响也能做到可控。
 
 3 MySQL 执行 join 语句的两种可能算法，这两种算法是由能否使用被驱动表的索引决定的 Index Nested-Loop Join（使用到了被驱动表上的索引） 和 Block Nested-Loop Join（没有使用到索引全表扫join_buffer比较）
 
 4 join 选择小表 小表的定义是两个表按照各自的条件过滤，过滤完成之后，计算参与 join 的各个字段的总数据量，数据量小的那个表，就是“小表”，应该作为驱动表。列子查询一个字段的表和所有字段的表作join 那么 一个字段的表为驱动表 
 
 5 Index Nested-Loop Join（NLJ）和 Block Nested-Loop Join（BNL）
 1 优化的方向就是给被驱动表的关联字段加上索引；2 基于临时表的改进方案，对于能够提前过滤出小数据的 join 语句来说，效果还是很好的；
 
 6 临时表和内存表的区别 
 内存表，指的是使用 Memory 引擎的表，建表语法是 create table … engine=memory。这种表的数据都保存在内存里，系统重启的时候会被清空，但是表结构还在。除了这两个特性看上去比较“奇怪”外，从其他的特征上看，它就是一个正常的表。而临时表，可以使用各种引擎类型 。如果是使用 InnoDB 引擎或者 MyISAM 引擎的临时表，写数据的时候是写到磁盘上的。当然，临时表也可以使用 Memory 引擎。
 
 7 临时表的特征 
 建表语法是 create temporary table …。一个临时表只能被创建它的 session 访问，对其他线程不可见。
 临时表可以与普通表同名。session A 内有同名的临时表和普通表的时候，show create 语句，以及增删改查语句访问的是临时表。
 show tables 命令不显示临时表。
 8 临时表一般用于处理比较复杂的计算逻辑 。bin log设置为row模式，临时表不会同步到备库中，设置为statement模式，会同步到备库中。
 
 9 MySQL 5.7 版本支持了 generated column 机制关联更新 如 alter table t1 add column z int generated always as(id % 100), add index(z);
 10 group by 优化 
 1如果对 group by 语句的结果没有排序要求，要在语句后面加 order by null；
 2 尽量让 group by 过程用上表的索引，确认方法是 explain 结果里没有 Using temporary 和 Using filesort；
 3 如果 group by 需要统计的数据量不大，尽量只使用内存临时表；
 4 也可以通过适当调大 tmp_table_size 参数，来避免用到磁盘临时表；
 5 如果数据量实在太大，使用 SQL_BIG_RESULT 这个提示，来告诉优化器直接使用排序算法得到 group by 的结果。

```
### 15 打卡学习 第四周 2020 03-16 2020 03-22
```sql
1 导出表数据 就是把数据库d 里的t a 大于900的导出来 成insert 语句
mysqldump -h$host -P$port -u$user --add-locks=0 --no-create-info --single-transaction  --set-gtid-purged=OFF db1 t --where="a>900" --result-file=/client_tmp/t.sql
2 快速的复制一张表  MySQL 5.6 版本引入了可传输表空间(transportable tablespace) 的方法
执行 create table r like t，创建一个相同表结构的空表；
执行 alter table r discard tablespace，这时候 r.ibd 文件会被删除；
执行 flush table t for export，这时候 db1 目录下会生成一个 t.cfg 文件；
在 db1 目录下执行 cp t.cfg r.cfg; cp t.ibd r.ibd；这两个命令（这里需要注意的是，拷贝得到的两个文件，MySQL 进程要有读写权限）；
执行 unlock tables，这时候 t.cfg 文件会被删除；
执行 alter table r import tablespace，将这个 r.ibd 文件作为表 r 的新的表空间，由于这个文件的数据内容和 t.ibd 是相同的，所以表 r 中就有了和表 t 相同的数据。
3 left join 的语义，就不能把被驱动表的字段放在 where 条件里面做等值判断或不等值判断，必须都写在 on 里面。
select * from a join b on(a.f1=b.f1) and (a.f2=b.f2); /*Q3*/
select * from a join b on(a.f1=b.f1) where (a.f2=b.f2);/*Q4*/ 改写为 join 语句
4 实际行排重后是13万，而count(distinct)确有38万为何
38万
select count(distinct(tid)) from tb_logs where ch='a'
13万
select count(*) from (select distinct(tid) from tb_logs where ch='a') t
这个问题 尝试看看复现一下

# 美团sql 优化文章
https://tech.meituan.com/2014/06/30/mysql-index.html
```
### 16 添加多个字段和重命名表
```
alter table table_name add (xx ,xxx);
alter table table_name rename to table_new;
```
### 17 分组后求最后一条记录
```
分组拼接id 然后截取 在inner join 
#截取最小记录
select SUBSTRING_INDEX(GROUP_CONCAT(valid_date order by id),',',1) From jct_emp_hire where emp_number = '1091034' group by emp_id;
#截取最大记录
select SUBSTRING_INDEX(GROUP_CONCAT(valid_date order by id desc),',',1) From jct_emp_hire where emp_number = '1091034' group by emp_id;
#截取特定第几条数据
select SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(valid_date order by id),',',4),',',-1) From jct_emp_hire where emp_number = '1091034' group by emp_id;

#取一个值的最新或者最早记录的
SELECT r.return_time
from 72crm_crm_receivables r WHERE c.contract_id=r.contract_id and c.owner_user_id=r.owner_user_id and check_status =1
ORDER BY r.return_time DESC LIMIT 1
) as return_time  from 72crm_crm_contract c  WHERE c.check_status =1
```
### 18 trim函数 过滤指定的字符串：
```
 去除首尾的,
 SELECT TRIM(BOTH ',' FROM ',50,9,10,11,22,24,25,28,29,30,37,38,42,44,45,46,47,48,49,51,52,53,54,55,7,4,');

```
### 19 判断数据是否存在
```
 0 否 1是
 select exists( select 1 from t_dict where DICT_ID =30 and KEYY =0 )
 ```         
### 20 行转列 动态拼接sql 使用扩展表里的k v 值和主表结合
 ```  
 #原来的sql
SELECT user_name, max(IF( SUBJECT = '数学', score, 0 )) AS '数学', 
max(IF( SUBJECT = '生物', score, 0 )) AS '生物',
max(IF( SUBJECT = '英语', score, 0 )) AS '英语',
max(IF( SUBJECT = '语文', score, 0 )) AS '语文' 
FROM sc GROUP BY user_name
user_name 数学    生物     英语    语文
张三	90	85	70	80
李四	90	85	70	80
 
 #动态 拼接
set @splice_sql = null;
SELECT 
    GROUP_CONCAT(DISTINCT
        CONCAT('max(if(subject=''',subject,''', score, 0)) as ''',subject, ''''))
    into @splice_sql
from sc;
set @splice_sql = CONCAT('select user_name,', @splice_sql, ' from sc group by user_name');
#预处理 相当于用占位符
prepare bella_test from @splice_sql;
#执行
execute bella_test;
#释放资源
DEALLOCATE prepare bella_test;

 #prepare 预处理
 https://www.cnblogs.com/geaozhang/p/9891338.html
 ```   
 ### 21 伪列
```
set @avg := -1;
select * from (select d.issue,d.q1,d.q2,d.q3,d.q4,d.q5,(@avg := @avg+1) average 
from dlt_result d order by d.issue asc) as tmp order by issue desc
https://www.cnblogs.com/shuilangyizu/p/7866479.html


 ``` 
				
