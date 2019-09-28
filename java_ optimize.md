
## 一 2019年09月22日

### 1 String intern() 方法

```pwd

例子
       String s1 = new String("1")+new String("1");
//      s1.intern(); 打开true 
        String s2="11";
        //false
        System.out.println(s1==s2);
        String s3 = new String("11");
        String intern = s3.intern();
        //false
        System.out.println(s3==s2);
        //true
        System.out.println(intern==s2);


对于字符串常量，在类加载时，会将字符串放入方法区中的静态常量池，包括字符串的字面量和字符引用。而在初始化或运行时，会将字符引用转为直接引用，存放在运行时常量池。
如果是运行时动态生成的字符串对象调用intern方法，如果字符串的引用在运行时常量池不存在，则会在常量池中创建一个引用。

所以第一个通过加动态生成的“11”字符串由于在运行时常量中没有该字符串的引用，所以会在调用s1.intern时，在运行时常量池中生成一个s1的引用，当s2再次引用该字符串时，发现运行时常量池中存在相同值的字符串的引用，就直接返回s1的引用。所以s1==s2是返回的true。这也仅限于JDK1.7之后的版本。
而第二种，用于"11"在类加载时，已经存在静态常量池中，在new string(“11”)时，会在运行时常量池中创建一个“11”字符串的直接引用。而s1指向的并不是该引用，而是new string这个对象的引用。当s2=“11”时，返回的是运行时常量池中的引用。所以s1==s2返回false
这里有个 char[] 地址复用是当常量池发现一样的常量对象是就会直接引用了不会在创建。但是并不代表他们的引用地址是一样的。如上面 第二种情况 s2 和s3 的char[]地址是一样的但是 他们引用地址并不相等

```

### 2 正则 表达式如何避免回溯问题

```pwd
1. 贪婪模式（Greedy）
顾名思义，就是在数量匹配中，如果单独使用 +、 ? 、* 或{min,max} 等量词，正则表达式会匹配尽可能多的内容。
2. 懒惰模式（Reluctant）
在该模式下，正则表达式会尽可能少地重复匹配字符。如果匹配成功，它会继续匹配剩余的字符串。例如加 ？
3. 独占模式（Possessive）
同贪婪模式一样，独占模式一样会最大限度地匹配更多内容；不同的是，在独占模式下，匹配失败就会结束匹配，不会发生回溯问题。例如加个 +
所以 正则表达式 多用 独占模式
```

### 3 ArrayList 和LinkList 性能对比

```pwd
1 增删方面 arraryList 如果是在头部地方 增加和删除性能比linkList 差 ，如果是在尾部添加元素没有扩容的话 性能比linkList好 但是扩容的就不一样了 中间的都差不多
2 查询的话 都可以通过索引来查 遍历的话 linklist 使用 iteator 遍历比for 循环效率高

```

### 4 分库分表的中间间 及分页查询

```pwd
中间件 sharing-jdbc（嵌入式）  mycat（proxy）性能差点
分页 将每个分表的数据查询出来 通过归并排序计算出来 stream api 
paralle 并行流 在处理集合时 如果时线程不安全的集合 就会有线程不安全的问题
stream  api 在处理大数据量集合比较好 对机器的cpu 要求时 多核 并行处理的效率比较高
```

### 5 hashMap 原理和优化
```pwd
 基于 数组加链表的数据结构来实现，通过将 Key 的 hash 值与 length-1 进行 & 运算，实现了当前 Key 的定位（存储位置），2 的幂次方可以减少冲突（碰撞）的次数，提高 HashMap 查询效率；如果相同node 超过8个 就会生成红黑树来存储 查询时间复杂度O（log(n)）
 重写 key 值的 hashCode() 方法，降低哈希冲突，从而减少链表的产生，高效利用哈希表，达到提高性能的效果。
 扩容 达到hashMap 的 负载因子（0.75）倍的长度 就会两倍扩容 而在 JDK 1.8 中，HashMap 对扩容操作做了优化。由于扩容数组的长度是 2 倍关系，所以对于假设初始 tableSize = 4 要扩容到 8 来说就是 0100 到 1000 的变化（左移一位就是 2 倍），在扩容中只用判断原来的 hash 值和左移动的一位（newtable 的值）按位与操作是 0 或 1 就行，0 的话索引不变，1 话是 扩容前索引位置加上扩容前数组长度的数值索引（原来是 4 之前是16  扩容后数组长度32 那么 新的索引是  20）
 
 假设链表中有4、8、12，他们的二进制位00000100、00001000、00001100，而原来数组容量为4，则是 00000100，以下与运算：
  00000100 & 00000100 = 0 保持原位
  00001000 & 00000100 = 1 移动到高位
  00001100 & 00000100 = 1 移动到高位

```
### 6 简单解释NIO

```pwd
1 传统 I/O 的性能问题(以字节为单位 效率低)
 多次内存复制 数据先从外部设备复制到内核空间，再从内核空间复制到用户空间，这就发生了两次内存复制操作。这种操作会导致不必要的数据拷贝和上下文切换，从而降低 I/O 的性能.
 在传统 I/O 中，InputStream 的 read() 是一个 while 循环操作，它会一直等待数据读取，直到数据就绪才会返回。这就意味着如果没有数据就绪，这个读取操作将会一直被挂起，用户线程将会处于阻塞状态。
2 NIO（以 block 块 为单位）
 使用缓冲区优化读写流操作 传统 I/O 和 NIO 的最大区别就是传统 I/O 是面向流，NIO 是面向 Buffer。Buffer 可以将文件一次性读入内存再做后续处理，而传统的方式是边读文件边处理数据。虽然传统 I/O 后面也使用了缓冲块，例如 BufferedInputStream，但仍然不能和 NIO 相媲美。使用 NIO 替代传统 I/O 操作，可以提升系统的整体性能。
 使用 DirectBuffer 减少内存复制 是直接将步骤简化为从内核空间复制到外部设备，减少了数据拷贝
3. 避免阻塞，优化 I/O 操作
 管道（channel）Channel 有自己的处理器，可以完成内核空间和磁盘之间的 I/O 操作。在 NIO 中，我们读取和写入数据都要通过 Channel，由于 Channel 是双向的，所以读、写可以同时进行。
 多路复用器（Selector）Selector 是基于事件驱动实现的，我们可以在 Selector 中注册 accpet、read 监听事件，Selector 会不断轮询注册在其上的 Channel，如果某个 Channel 上面发生监听事件，这个 Channel 就处于就绪状态，然后进行 I/O 操作。 避免阻塞

```
### 7 RPC 框架序列列化优化

```pwd
看一下 dubbo 采用protobuf 序列化协议
这里是dubbo 序列化扩展 目前没有扩展 protobuf协议 但是扩展了Kryo 可以参考KryoSerialization 实现方式实现 但是这个序列化方式在分布式环境下存在坑
官方文档 http://dubbo.apache.org/zh-cn/docs/dev/impls/serialize.html

最后，需要手动在 classpath 下创建 META-INF/dubbo/internel/org.apache.dubbo.common.serialize.Serialization 路径。 文件名称为：
org.apache.dubbo.common.serialize.Serialization。在该文件中写入自己的实现类，及该实现的 schema。例如：
protobuf=org.apache.dubbo.common.serialize.protocol.ProtobufSerialization

将自己的实现打包，注意打包的时候，一定要将 /META-INF 文件夹下的所有内容都打包进去。否则，将不会被 classloader 加载到，进而报错！

引入
<dubbo:protocol serialization="xxx" />

```

### 8 linux tcp 参数查看和优化

```pwd
查看命宁 sysctl -a | grep net.xxx （sysctl -a | grep net.ipv4.tcp_keepalive_time）
修改某项配置，可以通过编辑 vim/etc/sysctl.conf，加入需要修改的配置项， 并通过 sysctl -p 命令运行生效修改后的配置项设置。
下面配置提高网络吞吐量和降低延时
![storage](https://static001.geekbang.org/resource/image/9e/bc/9eb01fe017b267367b11170a864bd0bc.jpg)

```

