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
    wget http://download.redis.io/releases/redis-5.0.6.tar.gz
2. 解压到/usr/local目录下
   tar -xzvf redis-5.0.6.tar.gz -C /usr/local
3. 编译
   cd /usr/local/redis-5.0.6  && make
   如果make出错，尝试改用 make MALLOC=libc 编译。
4. 指定安装位置
   make install PREFIX=/usr/local/redis
5. 拷贝安装目录下配置文件到 /usr/local/redis/conf
   mkdir /usr/local/redis/conf
   cp  /usr/local/redis-5.0.6/redis.conf  /usr/local/redis/conf/
6. 修改配置文件 /usr/local/redis/etc/redis.conf
   vi /usr/local/redis/etc/redis.conf

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
   ```

7. 启动redis
   /usr/local/redis/bin/redis-server /usr/local/redis/etc/redis.conf
8. 查看是否启动成功
   查看进程:
   ps aux | grep redis
   查看日志:
   tail -fn 500 /usr/local/redis/log/redis_6379.log
   命令端验证:
   /usr/local/redis/bin/redis-cli -h 172.18.203.30 -p 6379
   172.18.203.30:6379> ping
   PONG

## 集群搭建

1. 服务器上搭建有3个节点的 Redis集群，在路径为/usr/local/redis/redis-cluster下创建3个文件夹代表3个实例。

   ```sh
   mkdir /usr/local/redis/redis-cluster
   cd /usr/local/redis/redis-cluster
   mkdir 7000 7001 7002
    ```

2. 分别给3个文件夹，创建日志、数据和配置文件存放路径：

   ```sh
   mkdir /usr/local/redis/redis-cluster/7000/conf
   mkdir /usr/local/redis/redis-cluster/7000/log
   mkdir /usr/local/redis/redis-cluster/7000/data
   mkdir /usr/local/redis/redis-cluster/7001/conf
   mkdir /usr/local/redis/redis-cluster/7001/log
   mkdir /usr/local/redis/redis-cluster/7001/data
   mkdir /usr/local/redis/redis-cluster/7002/conf
   mkdir /usr/local/redis/redis-cluster/7002/log
   mkdir /usr/local/redis/redis-cluster/7002/data
   ```

3. 进安装redis的目录分别将 redis.conf 配置文件 cp 到这3个目录，并将3个目录下的redis.config分别重名命为“文件名.conf”，例如：7000.conf


   ```sh
   cp  /usr/local/redis-5.0.6/redis.conf /usr/local/redis/redis-cluster/7000/conf/7000.conf
   cp  /usr/local/redis-5.0.6/redis.conf /usr/local/redis/redis-cluster/7001/conf/7001.conf
   cp  /usr/local/redis-5.0.6/redis.conf /usr/local/redis/redis-cluster/7002/conf/7002.conf
   ```

4. 分别进入目录修改配置文件

   ```sh
   port 7000                               # 修改端口号对应目录的端口号
   bind 0.0.0.0                            # Ip绑定 绑定本机ip或者改为 0.0.0.0
   /usr/local/redis/redis-cluster/7000     # 数据位置dir ./  改为>dir /usr/local/redis/redis-cluster/7000/data
   cluster-enabled yes                     # 启用集群模式
   cluster-config-file nodes-7000.conf     # 集群模式中节点的配置文件
   cluster-node-timeout 5000               # 超时时间
   appendonly yes                          # redis数据持久化开启，开启AOF模式
   daemonize yes                           # 后台运行
   protected-mode no                       # 非保护模式，允许 Redis 远程访问
   pidfile  /usr/local/redis/redis-cluster/7000/data/redis_7000.pid  # pidfile 需要随着文件夹的不同调增
   # 如需密码则修改如下配置
   requirepass "guoyuan" # 在：# requirepass foobared 下新增密码配置
   masterauth "密码"     # masterauth <master-password> 下新增密码配置
   ```

5. 加载3个redis配置文件启动

   ```sh
   # 进入redis的src目录启动redis (加载制定配置文件启动的方式)  6个都要启动，注意换配置文件位置
   redis-server /usr/local/redis/redis-cluster/7000/7000.conf
   redis-server /usr/local/redis/redis-cluster/7000/7001.conf
   redis-server /usr/local/redis/redis-cluster/7000/7002.conf
   redis-server /usr/local/redis/redis-cluster/7000/7003.conf
   redis-server /usr/local/redis/redis-cluster/7000/7004.conf
   redis-server /usr/local/redis/redis-cluster/7000/7005.conf
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
   /usr/local/redis/bin/redis-cli --cluster create 0.0.0.0:7000 0.0.0.0:7001 0.0.0.0:7002 --cluster-replicas 1
   ```

   安装过程中，输入 yes，Reids5 集群搭建完成。

## Redis5集群其他操作

Redis5 提供了关闭集群的工具，在如下目录：
/usr/local/redis-5.0.6/utils/create-cluster