---
title: Redis应用场景
date: 2018-03-08 14:51:06
tags: [cache, Redis]
---
# Redis应用场景

## Redis介绍

Redis是一个使用ANSI C编写的开源、支持网络、基于内存、可选持久性的键值对存储数据库。从2015年6月开始，Redis的开发由Redis Labs赞助，根据月度排行网站DB-Engines.com的数据显示，Redis是最流行的键值对存储数据库。

Redis的外围由一个键、值映射的字典构成。与其他非关系型数据库主要不同在于：Redis中值的类型不仅限于字符串，还支持如下抽象数据类型：

+ 字符串列表
+ 无序不重复的字符串集合
+ 有序不重复的字符串集合
+ 键、值都为字符串的哈希表

值的类型决定了值本身支持的操作。Redis支持不同无序、有序的列表，无序、有序的集合间的交集、并集等高级服务器端原子操作。

## Redis应用

### 会话缓存

最常用的一种使用Redis的情景是会话缓存（session cache）。用Redis缓存会话比其他存储（如Memcached）的优势在于：Redis提供持久化、Redis提供的数据类型丰富。例如：缓存用户的登录信息，由于用户登录信息有时比较复杂，如果采用json格式存储，使用起来会简单很多。

### 列出最新的项目列表

下面这个语句常用来显示最新项目，随着数据多了，查询毫无疑问会越来越慢。

```sql
SELECT * FROM foo WHERE … ORDER BY time DESC LIMIT 10;
```

应用中，“列出最新的回复”之类的查询非常普遍。如果数据库进行了分库分表的话，查询会变得复杂而且性能低下。类似的问题就可以用Redis来解决。比如说，我们的一个应用想要列出用户贴出的最新20条评论。我们假设数据库中的每条评论都有一个唯一的ID字段。我们可以使用分页来制作主页和评论页，使用Redis的模板，每次新评论发表时，我们会将它的ID添加到一个Redis列表：  
`LPUSH latest.comments`  
我们将列表裁剪为指定长度，因此Redis只需要保存最新的5000条评论：  
`LTRIM latest.comments 0 5000`

[LPUSH](http://redisdoc.com/list/lpush.html)  
LPUSH key value [value ...]  
将一个或多个值 value 插入到列表 key 的表头

[LTRIM](http://redisdoc.com/list/ltrim.html)  
LTRIM key start stop  
对一个列表进行修剪(trim)，就是说，让列表只保留指定区间内的元素，不在指定区间之内的元素都将被删除。

当我们需要获取最新评论的项目范围时，调用一个函数来完成(使用伪代码)：

```Java
    public List<Comment> getLatestComments(start, num_items) {
        id_list = redis.lrange("latest.comments",start,start+num_items – 1);
        if (id_list.length < num_items) {
            id_list = SQL_DB("SELECT … ORDER BY time LIMIT …"); 
        }
        return id_list;
    }
```

最新ID常驻在Redis中，并且一直是在更新的。但是我们做了限制不能超过5000个ID，因此我们的获取ID函数会一直询问Redis。只有在start/count参数超出了这个范围的时候，才需要去访问数据库。当然根据需求也可以不访问数据库。

### 排名

还有一个很普遍的需求是按得分排名，在按得分排序以及实时更新这些几乎每秒钟都需要更新的功能上数据库的性能不够理想。典型的比如那些在线游戏的排行榜，根据得分你通常想要：

+ 列出前100名高分选手
+ 列出某用户当前的全球排名

这些操作对于Redis来说很简单，即使你有几百万个用户，每分钟都会有几百万个新的得分。
模式是这样的，每次获得新得分时，我们用这样的代码：  
`ZADD userscore`  
得到前100名高分用户很简单：  
`ZREVRANGE userscore 0 99`  
用户的全球排名也相似，只需要：  
`ZRANK userscore`

[ZADD](http://redisdoc.com/sorted_set/zadd.html)  
ZADD key score member [[score member] [score member] ...]  
将一个或多个 member 元素及其 score 值加入到**有序集** key 当中。

[ZREVRANGE](http://redisdoc.com/sorted_set/zrevrange.html)  
ZREVRANGE key start stop [WITHSCORES]  
返回有序集 key 中，指定区间内的成员。其中成员的位置按 score 值递减(从大到小)来排列.

[ZRANK](http://redisdoc.com/sorted_set/zrank.html)  
ZRANK key member  
返回有序集 key 中成员 member 的排名。其中有序集成员按 score 值递增(从小到大)顺序排列。

### 延时任务

经常有类似的需求:

+ 订单生成后10分钟,如果用户不付款就关闭订单
+ 用户超时2天未收货，修改为自动收货

针对于类似这样的任务,一般我们是用定时任务来处理的。订单是存储在mysql的一个表里,表里会有各种状态和创建时间。利用quartz来设定一个定时任务,我们暂时设置为每5分钟扫描一次。扫描的条件为未付款并且当前时间大于创建时间超过15分钟.然后我们再去逐一的操作每一条数据。这个方案简单易用, 但扫表会增加程序负荷、任务执行不够准时。

还可以采用延时的方式来处理这样的问题，例如利用jdk自带的delayQueue。delayQueue的有点是：效率高,任务触发时间延迟低，不需要扫表，不会对数据库造成压力。但是delayQueue不支持分布式。

Redis有2种思路实现延时任务：

[ZREMRANGEBYSCORE](http://redisdoc.com/sorted_set/zremrangebyscore.html)  
ZREMRANGEBYSCORE key min max  
移除有序集 key 中，所有 score 值介于 min 和 max 之间的成员。  
时间复杂度: O(log(N)+M)， N 为有序集的基数，而 M 为被移除成员的数量。

+ 有序集合  
  使用 sorted Sets 的自动排序, key 为任务id，score 为任务计划执行时的时间戳，任务在 ZADD 加入 sets 后就已经按时间排序，然后采用 delayQueue 的思路每隔1s(或者其他间隔)用 ZRANGEBYSCORE 取出小于当前时间的的任务id 然后再去执行任务。

  由于有序集合中只有任务id，所以还需要一个哈希表来存储任务，有序集合和哈希表通过任务id关联起来。由于先从集合中取出到期的任务id，再从哈希表中取出任务，这是两次操作，可能出现不满足事务的情况发生。处理方法是采用 Redis 事务机制来实现事务，或者利用 Redis 执行 Lua 脚本是原子性的来采用Lua脚本封装这两个操作。

+ 键过期通知  
  Reids 2.8 后有一种“键空间”通知的机制 [Keyspace Notifications](http://redisdoc.com/topic/notification.html)，允许客户端去订阅一些key的事件，其中就有 key过期的事件，我们可以把 key 名称设置为 task 的 id 等标识(这种方式 value 的值无法取到，所以只用 key 来识别任务)，expire 设置为计划要执行的时间，然后设置一个客户端来订阅消息过期事件，然后处理 task。因为开启键空间通知功能需要消耗一些 CPU ，所以在默认配置下，该功能处于关闭状态。可以通过修改 redis.conf 文件，或者直接使用 CONFIGSET 命令来开启或关闭键空间通知功能。配置文件修改方式如下：
  ``` java
  notify-keyspace-events Ex  // 打开此配置，其中Ex表示键事件通知里面的key过期事件，每当有过期键被删除时，会发送通知
  ```
  + notify-keyspace-events 选项的参数为空字符串时，功能关闭。
  + 当参数不是空字符串时，功能开启。

  Redis 使用以下两种方式删除过期的键：
  + 当一个键被访问时，如果键已经过期，那么该键将被删除。
  + 底层系统会在后台渐进地查找并删除那些过期的键，从而处理那些已经过期、但是还没被访问到的键。当过期键被程序发现、并且将键从数据库中删除时，Redis 会产生一个 expired 通知。Redis 并不保证生存时间（TTL）变为 0 的键会立即被删除：如果程序没有访问这个过期键，或者带有生存时间的键非常多的话，那么在键的生存时间变为0 ，直到键真正被删除这中间，可能会有一段比较显著的时间间隔。  
    那么通知产生的时间会有一段间隔，如果不能接受这个间隔，可采用有序集合的方式来实现延时任务。

### 计数

Redis 是一个很好的计数器，它有 INCRBY 等命令。虽然可以用数据库做计数器，来获取统计或显示新信息，但数据库太慢了。使用 Redis 就不需要再担心了。有了原子递增(atomic increment)，你可以放心的加上各种计数，用GETSET重置，或者是让它们过期。例如这样操作：

``` bat
INCR user 60
```

计算出最近用户在页面间停顿超过或不超过60秒的页面浏览量。

[INCRBY](http://redisdoc.com/string/incrby.html)  
INCRBY key increment  
将 key 所储存的值加上增量 increment。如果 key 不存在，那么 key 的值会先被初始化为 0 ，然后再执行 INCRBY 命令。如果值包含错误的类型，或字符串类型的值不能表示为数字，那么返回一个错误。本操作的值限制在 64 位(bit)有符号数字表示之内。

### 指定时间内的特定项目

比如想要知道某些特定的注册用户或IP地址，他们到底有多少访问了某篇文章。在获得一次新的页面浏览时只需要这样做：

``` bat
SADD page:day0:
```

当然用unix时间替换day0，比如time()-(time()%3600*24)等等。想知道特定用户的数量吗?只需要使用

``` bat
SCARD page:day0:
```

计算某个特定用户是否访问了这个页面：

``` bat
SISMEMBER page:day0:
```

[SADD](http://redisdoc.com/set/sadd.html)  
SADD key member [member ...]  
将一个或多个 member 元素加入到集合 key 当中，已经存在于集合的 member 元素将被忽略。

[SCARD](http://redisdoc.com/set/scard.html)  
SCARD key  
返回集合 key 的基数(集合中元素的数量)。

[SISMEMBER](http://redisdoc.com/set/sismember.html)  
SISMEMBER key member  
判断 member 元素是否集合 key 的成员。

### 分布式锁

利用 SETNX 可实现分布式锁。

[SETNX](http://redisdoc.com/string/setnx.html)  
SETNX key value  
将 key 的值设为 value ，当且仅当 key 不存在。若给定的 key 已经存在，则 SETNX 不做任何动作。  
时间复杂度：O(1)  
返回值：设置成功，返回 1 。设置失败，返回 0 。  

设置成功会返回1，可表示拿到了锁，设置返回 0 表示没拿到锁，继续等待。释放锁可调用 DEL 删除 key。考虑到锁未释放而程序宕机，该锁将不会被释放的情况，可以给锁设置一个过期时间，过期后该锁会被 Redis 删除。
