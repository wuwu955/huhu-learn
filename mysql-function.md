## 记录工作中用到的sql 和函数

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
存储过程和存储函数的区别是 看参数和返回值 存储过程 参数必须是in 和必须有返回值 而存储过程 参数可以是 in,out,inout 类型 没有返回值
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
select VARIABLE_VALUE into @a from performance_schema.session_status where variable_name = 'Innodb_rows_read';
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

