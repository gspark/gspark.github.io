---
title: redis5伪集群搭建
date: 2019-11-18 16:51:51
tags: Redis
---

## Redis的发行版本解释

格式: major.minor.patchlevel
说明: major 主版本号
     minor 次版本号，如果为偶数表示当前版本是一个稳定版本，否则是一个非稳定版本(不适合生产环境使用)
     patchlevel 补丁bug修复

## 单机安装

1. 下载redis5.0.6二进制安装包
   wget [http://download.redis.io/releases/redis-5.0.6.tar.gz](http://download.redis.io/releases/redis-5.0.6.tar.gz)
2. 解压到/usr/local目录下
   tar -xzvf redis-5.0.6.tar.gz -C /usr/local
3. 编译
   cd /usr/local/redis-5.0.6  && make
   如果make出错，尝试改用 make MALLOC=libc 编译。
4. 指定安装位置
   make install PREFIX=/usr/local/redis
5. 拷贝安装目录下配置文件到 /usr/local/redis/conf
   mkdir /usr/local/redis/conf
   cp  /usr/local/redis-5.0.6/redis.conf /usr/local/redis/conf/
6. 修改配置文件 /usr/local/redis/conf/redis.conf
   vi /usr/local/redis/conf/redis.conf

   ```sh
   # 关闭保护模式
   protected-mode no
   # 以守护进程后台模式运行
   daemonize yes
   # 绑定本机ip
   bind 172.18.203.30
   # redis进程文件
   pidfile /usr/local/redis/redis_6379.pid
   # 日志文件
   logfile /usr/local/redis/log/redis_6379.log
   # 快照数据存放目录,一定是目录
   dir /usr/local/redis/data/
   # 认证密码
   requirepass 123456
   ```

   在redis目录创建log和data目录
7. 启动redis
   /usr/local/redis/bin/redis-server /usr/local/redis/conf/redis.conf
8. 查看是否启动成功
   查看进程:
   ps aux | grep redis
   查看日志:
   tail -fn 500 /usr/local/redis/log/redis_6379.log
   命令端验证:
   /usr/local/redis/bin/redis-cli -h 172.18.203.30 -p 6379
   172.18.203.30:6379> ping
   PONG
9. 停止redis服务
   /usr/local/redis/bin/redis-cli shutdown

## 集群搭建

   redis建议三主三从共6个节点组成redis集群，测试环境可一台物理上启动6个redis节点，但生产环境至少要准备3台物理机。

1. 服务器上搭建有6个节点的 Redis集群，在路径为/usr/local/redis/redis-cluster下创建6个文件夹代表6个实例。

   ```sh
   mkdir /usr/local/redis/redis-cluster
   cd /usr/local/redis/redis-cluster
   mkdir 7000 7001 7002 7003 7004 7005
    ```

2. 分别给这4个文件夹，创建日志、数据存放路径。配置文件放实例路径（如：7000）

   ```sh
   mkdir /usr/local/redis/redis-cluster/7000/log
   mkdir /usr/local/redis/redis-cluster/7000/data
   mkdir /usr/local/redis/redis-cluster/7001/log
   mkdir /usr/local/redis/redis-cluster/7001/data
   mkdir /usr/local/redis/redis-cluster/7002/log
   mkdir /usr/local/redis/redis-cluster/7002/data
   ```

3. 进安装redis-cluster的实例目录分别将 redis.conf 配置文件 cp 到这6个目录，并将3个目录下的redis.config分别重名命为“文件名.conf”，例如：7000.conf

   ```sh
   cp  /usr/local/redis-5.0.6/redis.conf /usr/local/redis/redis-cluster/7000/7000.conf
   cp  /usr/local/redis-5.0.6/redis.conf /usr/local/redis/redis-cluster/7001/7001.conf
   cp  /usr/local/redis-5.0.6/redis.conf /usr/local/redis/redis-cluster/7002/7002.conf
   ```

4. 分别进入目录修改配置文件

   ```sh
   # 修改端口号对应目录的端口号
   port 7000
   # Ip绑定 绑定本机ip或者改为 0.0.0.0
   bind 0.0.0.0
   # 数据位置dir ./  改为>dir /usr/local/redis/redis-cluster/7000/data
   dir /usr/local/redis/redis-cluster/7000/data
   # 启用集群模式
   cluster-enabled yes
   # 集群模式中节点的配置文件
   cluster-config-file nodes-7000.conf
   # 超时时间
   cluster-node-timeout 5000
   # redis数据持久化开启，开启AOF模式
   appendonly yes
   # 后台运行
   daemonize yes
   # 非保护模式，允许 Redis 远程访问
   protected-mode no
   # pidfile 需要随着文件夹的不同调增
   pidfile  /usr/local/redis/redis-cluster/7000/redis_7000.pid
   # 如需密码则修改如下配置
   # 在：# requirepass foobared 下新增密码配置
   requirepass "123456"
   # masterauth <master-password> 下新增密码配置
   masterauth "654321"
   ```

   nodes-7000.conf 文件不指定路径会在data生成。

5. 加载3个redis配置文件启动

   ```sh
   # 进入redis的src目录启动redis (加载制定配置文件启动的方式)  3个都要启动，注意换配置文件位置
   /usr/local/redis/bin/redis-server /usr/local/redis/redis-cluster/7000/7000.conf
   /usr/local/redis/bin/redis-server /usr/local/redis/redis-cluster/7001/7001.conf
   /usr/local/redis/bin/redis-server /usr/local/redis/redis-cluster/7002/7002.conf
   # ps进程看看是否都启动
   ps -ef|grep redis
   ```

### 创建redis集群

1. 创建redis4.x集群

   ```sh
   # 进入redis的src目录
   ./redis-trib.rb create --replicas 1 0.0.0.0:7000 0.0.0.0:7001 0.0.0.0:7002
   ```

   安装过程中，输入 yes，无报错，结尾出现[OK]即创建成功！
2. 创建redis5.x集群

   ```sh
   # redis5.x用redis-cli方式 不用redis4.x用的redis-trib.rb方式
   /usr/local/redis/bin/redis-cli --cluster create 0.0.0.0:7000 0.0.0.0:7001 0.0.0.0:7002 0.0.0.0:7003 0.0.0.0:7004 0.0.0.0:7005 --cluster-replicas 1 -a '123456'
   ```

   需先启动redis。
   --cluster-replicas 1 表示为集群中的每一个主节点指定一个从节点，即一比一的复制。
   安装过程中，输入 yes，Reids5 集群搭建完成。

## Redis5集群其他操作

Redis5 提供了关闭集群的工具，在如下目录：
/usr/local/redis-5.0.6/utils/create-cluster
打开此文件修改端口为我们自己的，如 6999。端口PROT设置为6999，NODES为6，工具会自动累加1 生成 7000-7005 六个节点 用于操作。
修改stop代码块：

```sh
if [ "$1" == "stop" ]
then
    while [ $((PORT < ENDPORT)) != "0" ]; do
        PORT=$((PORT+1))
        echo "Stopping $PORT"
        ./redis-cli -p $PORT -a "123456" shutdown nosave
    done
    exit 0
fi
```

### 关闭集群

执行 `create-cluster stop` 可关闭集群。

### 启动集群

执行 `create-cluster start` 可启动集群
建议启动脚本自己编写。

```sh
#!/bin/bash

PORT=6999
NODES=6

ENDPORT=$((PORT+NODES))

if [ "$1" == "start" ]
then
        /usr/local/redis/bin/redis-server /usr/local/redis/redis-cluster/7000/7000.conf
        /usr/local/redis/bin/redis-server /usr/local/redis/redis-cluster/7001/7001.conf
        /usr/local/redis/bin/redis-server /usr/local/redis/redis-cluster/7002/7002.conf
        /usr/local/redis/bin/redis-server /usr/local/redis/redis-cluster/7003/7003.conf
        /usr/local/redis/bin/redis-server /usr/local/redis/redis-cluster/7004/7004.conf
        /usr/local/redis/bin/redis-server /usr/local/redis/redis-cluster/7005/7005.conf
# 配置集群时执行一次
# /usr/local/redis/bin/redis-cli --cluster create 0.0.0.0:7000 0.0.0.0:7001 0.0.0.0:7002 0.0.0.0:7003 0.0.0.0:7004 0.0.0.0:7005 --cluster-replicas 1 -a '123456'
        exit 0
fi

if [ "$1" == "stop" ]
then
    while [ $((PORT < ENDPORT)) != "0" ]; do
        PORT=$((PORT+1))
        echo "Stopping $PORT"
        ./redis-cli -p $PORT -a "123456" shutdown nosave
    done
    exit 0
fi

echo "Usage: $0 [start|stop]"
echo "start       -- Launch Redis Cluster instances."
echo "stop        -- Stop Redis Cluster instances."
```
