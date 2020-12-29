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

## 编译

redis-6.x 开始的多线程代码依赖 C标准库中的新增类型 _Atomic 。但是 gcc 从 4.9 版本才开始正式和完整地支持 stdatomic（gcc-4.8.5 部分支持），而 centos7 默认的 gcc 版本为：4.8.5，无法正确的编译，所以需要升级 gcc 才能正确的编译 redis-6.x。升级方法：

``` sh
yum  -y  install  centos-release-scl
yum  -y  install  devtoolset-9-gcc  devtoolset-9-gcc-c++  devtoolset-9-binutils

#临时有效，退出 shell 或重启会恢复原 gcc 版本
scl enable devtoolset-9 bash
#长期有效
echo "source /opt/rh/devtoolset-9/enable" >>/etc/profile
```

redis 的编译方法见下文。

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

默认的bind 接口是127.0.0.1，也就是本地回环地址。这样的话，访问redis服务只能通过本机的客户端连接，而无法通过远程连接。
改成监听的网卡IP或者 0.0.0.0 可使任意IP均可访问。

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

2. 分别给这6个文件夹，创建日志、数据存放路径。配置文件放实例路径（如：7000）

   ```sh
   mkdir /usr/local/redis/redis-cluster/7000/log
   mkdir /usr/local/redis/redis-cluster/7000/data
   mkdir /usr/local/redis/redis-cluster/7001/log
   mkdir /usr/local/redis/redis-cluster/7001/data
   mkdir /usr/local/redis/redis-cluster/7002/log
   mkdir /usr/local/redis/redis-cluster/7002/data
   mkdir /usr/local/redis/redis-cluster/7003/log
   mkdir /usr/local/redis/redis-cluster/7003/data
   mkdir /usr/local/redis/redis-cluster/7004/log
   mkdir /usr/local/redis/redis-cluster/7004/data
   mkdir /usr/local/redis/redis-cluster/7005/log
   mkdir /usr/local/redis/redis-cluster/7005/data
   ```

3. 进安装redis-cluster的实例目录将 redis.conf 配置文件拷贝到 7000 这个目录，并重名命为 7000.conf

   ```sh
   cp  /usr/local/redis-5.0.6/redis.conf /usr/local/redis/redis-cluster/7000/7000.conf
   ```

4. 分别进入 7000 目录修改配置文件

   ```sh
   # 修改端口号对应目录的端口号
   port 7000
   # Ip绑定 绑定监听的网卡IP或者改为 0.0.0.0，
   bind 0.0.0.0
   # 数据位置dir ./  改为>dir /usr/local/redis/redis-cluster/7000/data
   dir /usr/local/redis/redis-cluster/7000/data
   # 启用集群模式
   cluster-enabled yes
   # 集群模式中节点的配置文件，文件不指定路径会在data生成
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
   pidfile /usr/local/redis/redis-cluster/7000/redis_7000.pid
   # 日志文件
   logfile /usr/local/redis/redis-cluster/7000/log/redis_7000.log
   # 如需密码则修改如下配置
   # 在：# requirepass foobared 下新增密码配置
   requirepass 123456
   # masterauth <master-password> 下新增密码配置
   masterauth 654321
   # nat或容器，内外网地址不一样的情况下，配置 cluster-announce-ip 为外网地址
   cluster-announce-ip 212.64.5.128
   ```

5. 拷贝 7000.conf 到其它配置目录

   ```sh
   cp /usr/local/redis/redis-cluster/7000/redis.conf /usr/local/redis/redis-cluster/7001/7001.conf
   cp /usr/local/redis/redis-cluster/7000/redis.conf /usr/local/redis/redis-cluster/7002/7002.conf
   cp /usr/local/redis/redis-cluster/7000/redis.conf /usr/local/redis/redis-cluster/7003/7003.conf
   cp /usr/local/redis/redis-cluster/7000/redis.conf /usr/local/redis/redis-cluster/7004/7004.conf
   cp /usr/local/redis/redis-cluster/7000/redis.conf /usr/local/redis/redis-cluster/7005/7005.conf
   ```

6. 如上例修改剩下的 5 个配置，将 7000 改成对应的目录，如7001、7002等

7. 加载 6 个redis配置文件启动

   ```sh
   # 进入redis的src目录启动redis (加载制定配置文件启动的方式)  6个都要启动，注意换配置文件位置
   /usr/local/redis/bin/redis-server /usr/local/redis/redis-cluster/7000/7000.conf
   /usr/local/redis/bin/redis-server /usr/local/redis/redis-cluster/7001/7001.conf
   /usr/local/redis/bin/redis-server /usr/local/redis/redis-cluster/7002/7002.conf
   /usr/local/redis/bin/redis-server /usr/local/redis/redis-cluster/7003/7003.conf
   /usr/local/redis/bin/redis-server /usr/local/redis/redis-cluster/7004/7004.conf
   /usr/local/redis/bin/redis-server /usr/local/redis/redis-cluster/7005/7005.conf
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

3. 重建集群
   先停止服务，再把各个节点下的 appendonly.aof，dump.rdb，nodes.conf 删除后，重建集群即可。删除各节点 data 中的文件。

   ```sh
   rm -f /usr/local/redis/redis-cluster/7000/data/*
   rm -f /usr/local/redis/redis-cluster/7001/data/*
   rm -f /usr/local/redis/redis-cluster/7002/data/*
   rm -f /usr/local/redis/redis-cluster/7003/data/*
   rm -f /usr/local/redis/redis-cluster/7004/data/*
   rm -f /usr/local/redis/redis-cluster/7005/data/*
   ```

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

### 查看集群状态

``` sh
// 查看节点详细信息
redis-cli -a '123456' -p 7000 cluster info
// 查看所有节点
redis-cli -a '123456' -p 7000 cluster nodes
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

## redis 启动 3 个警告

### overcommit_memory 报警

WARNING overcommit_memory is set to 0! Background save may fail under low memory condition. To fix this issue add 'vm.overcommit_memory = 1' to /etc/sysctl.conf and then reboot or run the command 'sysctl vm.overcommit_memory=1' for this to take effect.

内核参数 overcommit_memory，它是 内存分配策略
可选值：0、1、2。
0: 表示内核将检查是否有足够的可用内存供应用进程使用；如果有足够的可用内存，内存申请允许；否则，内存申请失败，
   并把错误返回给应用进程。
1: 表示内核允许分配所有的物理内存，而不管当前的内存状态如何。
2: 表示内核允许分配超过所有物理内存和交换空间总和的内存

Linux 对大部分申请内存的请求都回复"yes"，以便能跑更多更大的程序。因为申请内存后，并不会马上使用内存。这种技术叫做 Overcommit。当 linux 发现内存不足时，会发生OOM killer(OOM=out-of-memory)。它会选择杀死一些进程(用户态进程，不是内核线程)，以便释放内存。
当 oom-killer 发生时，linux 会选择杀死哪些进程？选择进程的函数是 oom_badness 函数(在 mm/oom_kill.c 中)，该函数会计算每个进程的点数(0~1000)。点数越高，这个进程越有可能被杀死。每个进程的点数跟 oom_score_adj 有关，而且 oom_score_adj 可以被设置(-1000最低，1000最高)。

解决方法：
按提示的操作（将vm.overcommit_memory 设为1）即可：
有三种方式修改内核参数，但要有root权限：（直接修改宿主机的配置文件）

1. 编辑/etc/sysctl.conf ，添加 vm.overcommit_memory=1，然后 sysctl -p 使配置文件生效
2. sysctl vm.overcommit_memory=1
3. echo 1 > /proc/sys/vm/overcommit_memory

### 关闭THP

WARNING you have Transparent Huge Pages (THP) support enabled in your kernel. This will create latency and memory usage issues with Redis. To fix this issue run the command 'echo madvise > /sys/kernel/mm/transparent_hugepage/enabled' as root, and add it to your /etc/rc.local in order to retain the setting after a reboot. Redis must be restarted after THP is disabled (set to 'madvise' or 'never').

Linux kernel 在2.6.38内核增加了 THP 特性， 支持大内存页（2MB） 分配， 默认开启。 当开启时可以降低 fork 子进程的速度， 但 fork 操作之后， 每个内存页从原来4KB变为2MB， 会大幅增加重写期间父进程内存消耗。 同时每次写命令引起的复制内存页单位放大了512倍， 会拖慢写操作的执行时间， 导致大量写操作慢查询， 例如简单的 incr 命令也会出现在慢查询中。 因此 Redis 日志中建议将此特性进行禁用。

redis 给出的解决方案是将 THP 设置为 madvise 或 never。`echo never > /sys/kernel/mm/transparent_hugepage/enabled`。
为了使机器重启后 THP 配置依然生效，可以在 /etc/rc.local 中追加"echo never>/sys/kernel/mm/transparent_hugepage/enabled"。

### The TCP backlog setting

WARNING: The TCP backlog setting of 511 cannot be enforced because /proc/sys/net/core/somaxconn is set to the lower value of 128.

将 net.core.somaxconn=1024 添加到 /etc/sysctl.conf 中，然后执行 sysctl -p 生效配置。
