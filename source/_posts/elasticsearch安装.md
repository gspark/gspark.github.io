---
title: elasticsearch安装
date: 2019-08-08 17:28:45
tags: software
---

## elasticsearch安装

### 安装

从 elastic 的官网 elastic.co/downloads/elasticsearch 获取最新版本的 Elasticsearch。
当你准备在生产环境安装 Elasticsearch 时，你可以在 官网下载地址 找 到 Debian 或者 RPM 包，除此之外，你也可以使用官方支持的 Puppet module 或者 Chef cookbook。
当你解压好了归档文件之后，Elasticsearch 已经准备好运行了。按照下面的操作，在前台(foregroud)启动 Elasticsearch：

```sh
cd elasticsearch-<version>
./bin/elasticsearch  
```

如果你想把 Elasticsearch 作为一个守护进程在后台运行，那么可以在后面添加参数 -d 。
如果你是在 Windows 上面运行 Elasticseach，你应该运行 bin\elasticsearch.bat 而不是 bin\elasticsearch 。
测试 Elasticsearch 是否启动成功，可以打开另一个终端，执行以下操作：

```sh
curl 'http://localhost:9200/?pretty'
```

### 配置

#### jdk

elasticsearch 的7.3.0需要jdk11，安装包自带了，如果环境中JAVA_HOME不是jdk11的话，修改`bin\elasticsearch-env`脚本，如下：

```sh
# now set the path to java
##if [ ! -z "$JAVA_HOME" ]; then
##  JAVA="$JAVA_HOME/bin/java"
##else
  if [ "$(uname -s)" = "Darwin" ]; then
    # OSX has a different structure
    JAVA="$ES_HOME/jdk/Contents/Home/bin/java"
  else
    JAVA="$ES_HOME/jdk/bin/java"
  fi
##fi
```

将java路径设置成elasticsearch带的jdk路径。

#### 远程地址

默认情况下，Elasticsearch 只允许本机访问，如果需要远程访问，可以修改 Elasticsearch 安装目录中的`config/elasticsearch.yml`文件，去掉network.host的注释，将它的值改成0.0.0.0，让任何人都可以访问，然后重新启动 Elasticsearch 。

### 停止

获取PID

```sh
$ jps | grep Elasticsearch
14542 Elasticsearch
```

或者

```sh
$ ./bin/elasticsearch -p /tmp/elasticsearch-pid -d
$ cat /tmp/elasticsearch-pid && echo
15516
kill -SIGTERM 15516
```

### 启动问题

#### org.elasticsearch.bootstrap.StartupException: java.lang.RuntimeException: can not run elasticsearch as root

不能用root身份登录
解决办法：

```sh
groupadd student
useradd es -g student -p 123
chown -R es:student elasticsearch-7.0.0
```

or

```sh
adduser es
passwd es
sudo chown -R es elasticsearch-<version>/
```

#### max file descriptors [4096] for elasticsearch process is too low, increase to at least [65535]

问题翻译过来就是：elasticsearch用户拥有的可创建文件描述的权限太低，至少需要65536；

解决办法：

```sh
切换到root用户修改
#vim /etc/security/limits.conf
在最后面追加下面内容
*** hard nofile 65536
*** soft nofile 65536
```

*** 是启动ES的用户
退出用户重新登录，使配置生效
重新 ulimit -Hn  查看硬限制 会发现数值有4096改成65535

#### max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]

问题翻译过来就是：elasticsearch用户拥有的内存权限太小，至少需要262144；

解决办法：

```sh
切换到root用户,执行命令：
#sysctl -w vm.max_map_count=262144
查看结果：
#sysctl -a|grep vm.max_map_count
显示：
vm.max_map_count = 262144
```

上述方法修改之后，如果重启虚拟机将失效，所以：
解决办法：
在 /etc/sysctl.conf 文件最后添加一行
vm.max_map_count=262144
即可永久修改

#### the default discovery settings are unsuitable for production use; at least one of [discovery.seed_hosts, discovery.seed_providers, cluster.initial_master_nodes] must be configured

默认的发现设置不适合生产使用;至少有一个[发现]。seed_hosts,发现。seed_providers,集群。必须配置initial_master_nodes]

这时候继续编辑elasticsearch.yml文件
将 #cluster.initial_master_nodes: ["node-1", "node-2"]
修改为 cluster.initial_master_nodes: ["node-1"]，记得保存。
