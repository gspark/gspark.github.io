---
title: 'jedis报错:No reachable node in cluster'
date: 2018-08-23 15:09:33
tags: [cache, Redis]
---
# jedis报错:No reachable node in cluster

服务器掉电重启后，java项目报错了：

```html
org.springframework.data.redis.RedisConnectionFailureException: No reachable node in cluster; nested exception is redis.clients.jedis.exceptions.JedisNoReachableClusterNodeException: No reachable node in cluster  
    at org.springframework.data.redis.connection.jedis.JedisExceptionConverter.convert(JedisExceptionConverter.java:67)  
    at org.springframework.data.redis.connection.jedis.JedisExceptionConverter.convert(JedisExceptionConverter.java:41)  
    at org.springframework.data.redis.PassThroughExceptionTranslationStrategy.translate(PassThroughExceptionTranslationStrategy.java:37)  
    at org.springframework.data.redis.connection.jedis.JedisClusterConnection.convertJedisAccessException(JedisClusterConnection.java:3696)  
    at org.springframework.data.redis.connection.jedis.JedisClusterConnection.get(JedisClusterConnection.java:546)  
    at org.springframework.data.redis.connection.DefaultStringRedisConnection.get(DefaultStringRedisConnection.java:284)  
    at org.springframework.data.redis.core.DefaultValueOperations$1.inRedis(DefaultValueOperations.java:46)  
    at org.springframework.data.redis.core.AbstractOperations$ValueDeserializingRedisCallback.doInRedis(AbstractOperations.java:54)  
    at org.springframework.data.redis.core.RedisTemplate.execute(RedisTemplate.java:204)  
    at org.springframework.data.redis.core.RedisTemplate.execute(RedisTemplate.java:166)  
    at org.springframework.data.redis.core.AbstractOperations.execute(AbstractOperations.java:88)  
    at org.springframework.data.redis.core.DefaultValueOperations.get(DefaultValueOperations.java:43)  
    at com.jhqc.pxsj.msa.pub.redis.RedisForStringServiceImpl.get(RedisForStringServiceImpl.java:29)
```

应是redis cluster出问题了，对解决方法做个记录备忘。

1. 重启redis集群
2. 检测redis 节点

    ``` bash
    ./redis-trib.rb check  192.168.31.233:7000
    ```

    但是出现如下错误信息：

    ```bash
    >>> Check for open slots...

    [WARNING] Node 192.168.31.233:7000 has slots in importing state (19816).

    [WARNING] Node 192.168.31.233:7001 has slots in migrating state (19816).

    [WARNING] The following slots are open: 19816
    ```

    尝试用：`redis-trib.rb fix 192.168.31.233:7000` 提示：`[ERR] Calling MIGRATE: ERR Syntax error, try CLIENT (LIST | KILL | GETNAME | SETNAME | PAUSE | REPLY)`
3. 清理 slot

    使用命令：`cluster setslot 19816 stable`  清理id为19816有问题的slot。  
    note：服务器cluster命令没有找到，通过RedisDesktopManager连接上每个节点，执行上面的命令。
4. 重启redis cluster
5. 重启java服务
    没重启java服务，客户端同样报错，重启后正常。


