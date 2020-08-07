---
title: Kafka日志管理
date: 2020-07-22 14:17:14
tags:
---

Kafka 启动后，会产生很多日志，包括程序运行日志和消息日志，存在把磁盘撑爆的风险，所以为了 Kafka 能够正常的运行，对它进行日志管理是必要的一环。

## Kafka运行日志

### 修改kafka-run-class.sh

Kafka 运行时日志默认输出到 $KAFKA_HOME/logs 目录下，需要将日志输出到指定分区(应该选择一个磁盘空间比较大的分区)。
比如 /data/kafka/logs 目录下。

修改脚本 $KAFKA_HOME/bin/kafka-run-class.sh。

`$KAFKA_HOME` 为 Kafka 的安装路径。

打开 kafka-run-class.sh，定位到LOG_DIR

```sh
# Log directory to use
if [ "x$LOG_DIR" = "x" ]; then
  LOG_DIR="$base_dir/logs"
fi
```

增加一行，修改为

```sh
LOG_DIR=/data/kafka/logs
# Log directory to use
if [ "x$LOG_DIR" = "x" ]; then
  LOG_DIR="$base_dir/logs"
fi
```

### log4j.properties

Kafka 采用 log4j 进行日志信息输送控制，Kafka 日志管理的配置文件为 log4j.properties，位于$KAFKA_HOME/config/log4j.properties。
在生产环境下，建议把日志级别改为 error 级。
Kafka 的 log4j.properties 中采用 DailyRollingFileAppender 按天进行日志备份，不支持只保留最近 n 天的数据，时间一久导致日志文件很多，
并且一天的文件有可能比较大，所以可以把 DailyRollingFileAppender 改成 RollingFileAppender，限制日志文件的大小和备份的个数。

**但如果要求必须按天保存的话，也就只能 DailyRollingFileAppender 进行日志备份了，这时就要注意定期进行日志的清理，避免大量的日志撑爆磁盘。**
下面是一个修改日志级别，并采用 RollingFileAppender，进行日志备份的例子：

```sh
log4j.rootLogger=ERROR, default

log4j.appender.default=org.apache.log4j.RollingFileAppender
log4j.appender.default.File=${kafka.logs.dir}/default.log
log4j.appender.default.MaxBackupIndex = 10
log4j.appender.default.MaxFileSize = 100MB
log4j.appender.default.layout=org.apache.log4j.PatternLayout
log4j.appender.default.layout.ConversionPattern=[%d] %p %m (%c)%n


log4j.appender.kafkaAppender=org.apache.log4j.RollingFileAppender
log4j.appender.kafkaAppender.File=${kafka.logs.dir}/server.log
log4j.appender.kafkaAppender.MaxBackupIndex = 10
log4j.appender.kafkaAppender.MaxFileSize = 100MB
log4j.appender.kafkaAppender.layout=org.apache.log4j.PatternLayout
log4j.appender.kafkaAppender.layout.ConversionPattern=[%d] %p %m (%c)%n


log4j.appender.stateChangeAppender=org.apache.log4j.RollingFileAppender
log4j.appender.stateChangeAppender.File=${kafka.logs.dir}/state-change.log
log4j.appender.stateChangeAppender.MaxBackupIndex = 10
log4j.appender.stateChangeAppender.MaxFileSize = 100MB
log4j.appender.stateChangeAppender.layout=org.apache.log4j.PatternLayout
log4j.appender.stateChangeAppender.layout.ConversionPattern=[%d] %p %m (%c)%n


log4j.appender.requestAppender=org.apache.log4j.RollingFileAppender
log4j.appender.requestAppender.File=${kafka.logs.dir}/kafka-request.log
log4j.appender.requestAppender.MaxBackupIndex = 10
log4j.appender.requestAppender.MaxFileSize = 100MB
log4j.appender.requestAppender.layout=org.apache.log4j.PatternLayout
log4j.appender.requestAppender.layout.ConversionPattern=[%d] %p %m (%c)%n


log4j.appender.cleanerAppender=org.apache.log4j.RollingFileAppender
log4j.appender.cleanerAppender.File=${kafka.logs.dir}/log-cleaner.log
log4j.appender.cleanerAppender.MaxBackupIndex = 10
log4j.appender.cleanerAppender.MaxFileSize = 100MB
log4j.appender.cleanerAppender.layout=org.apache.log4j.PatternLayout
log4j.appender.cleanerAppender.layout.ConversionPattern=[%d] %p %m (%c)%n


log4j.appender.controllerAppender=org.apache.log4j.RollingFileAppender
log4j.appender.controllerAppender.File=${kafka.logs.dir}/controller.log
log4j.appender.controllerAppender.MaxBackupIndex = 10
log4j.appender.controllerAppender.MaxFileSize = 100MB
log4j.appender.controllerAppender.layout=org.apache.log4j.PatternLayout
log4j.appender.controllerAppender.layout.ConversionPattern=[%d] %p %m (%c)%n

log4j.appender.authorizerAppender=org.apache.log4j.RollingFileAppender
log4j.appender.authorizerAppender.File=${kafka.logs.dir}/kafka-authorizer.log
log4j.appender.authorizerAppender.MaxBackupIndex = 10
log4j.appender.authorizerAppender.MaxFileSize = 100MB
log4j.appender.authorizerAppender.layout=org.apache.log4j.PatternLayout
log4j.appender.authorizerAppender.layout.ConversionPattern=[%d] %p %m (%c)%n


# Change the line below to adjust ZK client logging
log4j.logger.org.apache.zookeeper=WARN

# Change the two lines below to adjust the general broker logging level (output to server.log and stdout)
log4j.logger.kafka=ERROR
log4j.logger.org.apache.kafka=ERROR

# Change to DEBUG or TRACE to enable request logging
log4j.logger.kafka.request.logger=ERROR, requestAppender
log4j.additivity.kafka.request.logger=false

# Uncomment the lines below and change log4j.logger.kafka.network.RequestChannel$ to TRACE for additional output
# related to the handling of requests
#log4j.logger.kafka.network.Processor=TRACE, requestAppender
#log4j.logger.kafka.server.KafkaApis=TRACE, requestAppender
#log4j.additivity.kafka.server.KafkaApis=false
log4j.logger.kafka.network.RequestChannel$=WARN, requestAppender
log4j.additivity.kafka.network.RequestChannel$=false

log4j.logger.kafka.controller=ERROR, controllerAppender
log4j.additivity.kafka.controller=false

log4j.logger.kafka.log.LogCleaner=ERROR, cleanerAppender
log4j.additivity.kafka.log.LogCleaner=false

log4j.logger.state.change.logger=ERROR, stateChangeAppender
log4j.additivity.state.change.logger=false
```

注意：
**上述配置中的文件大小、备份日志文件个数和日志级别需要根据环境和要求进行调整**

## Kafka的数据

Kafka 的数据有时也会称为日志或消息，请不要与运行日志混淆。
在 $KAFKA_HOME/config/server.properties 中配置了 log.dirs 值，表示 Kafka 数据的存放目录，而非 Kafka 的运行日志目录。

### 日志/消息清理（delete）

Kafka 消息日志的清理逻辑是启动线程定期扫描日志文件，将符合清理规则的消息日志文件删除。
Kafka 默认的清理策略是基于文件修改时间戳的清理策略，默认会保留 7 天的消息日志量，基于消息日志总量大小的清理规则不生效。
在 $KAFKA_HOME/config/server.properties 中 log.retention.hours 配置了该值：

```sh
# The minimum age of a log file to be eligible for deletion due to age
log.retention.hours=168
```

单位是小时，刚好 7 天。

**因此，Kafka 数据的存放目录也一定要考虑磁盘空间是否能够满足保存7天的消息日志量，避免出现磁盘空间不够的情况。**

Kafka 还可以基于消息日志大小进行清理，该策略会依次检查每个日志中的日志分段是否超出指定的大小（retentionSize），对超出指定大小的日志分段采取
删除策略。retentionSize 可通过参数 log.retention.bytes 来配置（在 $KAFKA_HOME/config/server.properties 中），单位为字节，
默认值为 -1，表示无穷大。该参数配置的是Log中所有日志文件的总大小，并非单个日志分段的大小。Kafka 的默认配置是基于上述的时间段清理，该参数是注释
状态。

```sh
# A size-based retention policy for logs. Segments are pruned from the log unless the remaining
# segments drop below log.retention.bytes. Functions independently of log.retention.hours.
#log.retention.bytes=1073741824
```

单个日志分段文件的大小限制可通过 log.segment.bytes 来限制，默认为1073741824，即1GB。

## 运行建议

建议在 Kafka 运行期间 对 Kafka 运行日志和消息进行监控，总结分析出每天的日志量的大小，合理规划磁盘空间和时间，
定期对 Kafka 的运行日志和消息进行备份和清理。
