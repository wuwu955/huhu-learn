
## 一 2019年09月15日

### 1 需要掌握的常用数据结构和算法

```pwd
10个数据结构：数组、链表、栈、队列、散列表、二叉树、堆、跳表、图、Trie
10 个算法：递归、排序、二分查找、搜索、哈希算法、贪心算法、分治算法、回溯算法、动态规划、字符串匹配算法。
```

### 2 学习技巧

```pwd
1. 边学边练，适度刷题
  边学边练”这一招非常有用。建议你每周花 1～2 个小时的时间，集中把这周的三节内容涉及的数据结构和算法，全都自己写出来，
  用代码实现一遍。这样一定会比单纯地看或者听的效果要好很多！
2. 多问、多思考、多互动 
  比如，针对这个专栏，你就可以设立这样一个目标：每节课后的思考题都认真思考，并且回复到留言区。当你看到很多人给你点赞之后，
你就会为了每次都能发一个漂亮的留言，而更加认真地学习。
```

### 3 时间复杂度分析

```pwd
1.大O表示法
1）来源
算法的执行时间与每行代码的执行次数成正比，用T(n) = O(f(n))表示，其中T(n)表示算法执行总时间，f(n)表示每行代码执行总次数，而n往往表示数据的规模。
2）特点
以时间复杂度为例，由于时间复杂度描述的是算法执行时间与数据规模的增长变化趋势，所以常量阶、低阶以及系数实际上对这种增长趋势不产决定性影响，
所以在做时间复杂度分析时忽略这些项。
2.复杂度分析法则
1）单段代码看高频：比如循环。单次 O（n）,多次O(n^2)
2）多段代码取最大：比如一段代码中有单循环和多重循环，那么取多重循环的复杂度。
3）嵌套代码求乘积：比如递归、多重循环等
4）多个规模求加法：比如方法有两个参数控制两个循环的次数，那么这时就取二者复杂度相加。
3、常用的复杂度级别？
多项式阶：随着数据规模的增长，算法的执行时间和空间占用，按照多项式的比例增长。包括，
O(1)（常数阶）、O(logn)（对数阶）、O(n)（线性阶）、O(nlogn)（线性对数阶）、O(n^2)（平方阶）、O(n^3)（立方阶）
非多项式阶：随着数据规模的增长，算法的执行时间和空间占用暴增，这类算法性能极差。包括，
O(2^n)（指数阶）、O(n!)（阶乘阶）

一、复杂度分析的4个概念
1.最好情况时间复杂度：代码在最理想情况下执行的时间复杂度。
2.最坏情况时间复杂度：代码在最坏情况下执行的时间复杂度。
3.平均时间复杂度：用代码在所有情况下执行的次数的加权平均值表示。
4.均摊时间复杂度：在代码执行的所有复杂度情况中绝大部分是低级别的复杂度，个别情况是高级别复杂度且发生具有时序关系时，
可以将个别高级别复杂度均摊到低级别复杂度上。基本上均摊结果就等于低级别复杂度。

二、为什么要引入这4个概念？
1.同一段代码在不同情况下时间复杂度会出现量级差异，为了更全面，更准确的描述代码的时间复杂度，所以引入这4个概念。
2.代码复杂度在不同情况下出现量级差别时才需要区别这四种复杂度。大多数情况下，是不需要区别分析它们的。

三、如何分析平均、均摊时间复杂度？
1.平均时间复杂度
代码在不同情况下复杂度出现量级差别，则用代码所有可能情况下执行次数的加权平均值表示。
2.均摊时间复杂度
两个条件满足时使用：1）代码在绝大多数情况下是低级别复杂度，只有极少数情况是高级别复杂度；2）低级别和高级别复杂度出现具有时序规律。
均摊结果一般都等于低级别复杂度。

```

### 4 数组优化新增和删除时间复杂度

```pwd
数组是（array）是一种线性表数据结构。它用一组连续的内存空间，来存储一组具有相同类型的数据。
重点是 连续 和存储相同类型数据

插入：
若有一元素想往int[n]的第k个位置插入数据，需要在k-n的位置往后移。
最好情况时间复杂度 O(1)
最坏情况复杂度为O(n)
平均负责度为O(n)
如果数组中的数据不是有序的，也就是无规律的情况下，可以直接把第k个位置上的数据移到最后，然后将插入的数据直接放在第k个位置上。
这样时间复杂度就将为 O（1）了。

删除：
与插入类似，为了保持内存的连续性。
最好情况时间复杂度 O(1)
最坏情况复杂度为O(n)
平均负责度为O(n)
提高效率：将多次删除操作中集中在一起执行，可以先记录已经删除的数据，但是不进行数据迁移，而仅仅是记录，当发现没有更多空间存储时，
再执行真正的删除操作。这也是 JVM 标记清除垃圾回收算法的核心思想。

```

### 5 链表 实现LRU缓存淘汰算法

```pwd

从链表中查询此缓存数据是否存在：
1、如果存在，则删除该缓存数据节点，并把数据插入到链表头部的位置；
1、如果不存在，则也考虑两种情况：
    1、如果缓存充足，则把数据插入到链表头部的位置；
    2、如果缓存不足，则把链表中的末尾节点删除，再把缓存数据插入到头部。
如何通过单链表实现“判断某个字符串是否为水仙花字符串”？（比如 上海自来水来自海上）
1）前提：字符串以单个字符的形式存储在单链表中。
2）遍历链表，判断字符个数是否为奇数，若为偶数，则不是。
3）将链表中的字符倒序存储一份在另一个链表中。
4）同步遍历2个链表，比较对应的字符是否相等，若相等，则是水仙花字串，否则，不是。
```

