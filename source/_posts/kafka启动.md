---
title: kafka启动
date: 2018-08-21 11:16:01
tags: kafka
---

# 启动kafka

启动前需要先查看ZooKeeper是否已经安装启动

## 前台启动kafka

```bash
./bin/kafka-server-start.sh ./config/server.properties
```

## 后台启动kafka

```bash
nohup ./bin/kafka-server-start.sh config/server.properties &
或者
./bin/kafka-server-start.sh -daemon config/server.properties
```

## 检查kafka是否启动

```bash
jps -l | grep kafka
输出：
16318 kafka.Kafka
```
