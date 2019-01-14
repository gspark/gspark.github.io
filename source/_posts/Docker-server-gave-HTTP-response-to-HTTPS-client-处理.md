---
title: Docker server gave HTTP response to HTTPS client 处理
date: 2019-01-14 17:13:03
tags: [docker]
---
# Docker server gave HTTP response to HTTPS client 处理

## 镜像推送

向私有仓库推送镜像的时候，提示server gave HTTP response to HTTPS client，出现这问题的原因是：Docker自从1.3.X之后docker registry交互默认使用的是HTTPS，但是搭建私有镜像默认使用的是HTTP服务，所以与私有镜像交时出现以上错误。
解决方法为：

1. 修改/etc/docker/daemon.json文件  

   内容如下，加入 insecure-registries  

```sh
    {
        "registry-mirrors": ["https://rqyzl64n.mirror.aliyuncs.com"],
        "insecure-registries": ["myregistry.example.com:5000"]
    }
```

2. 重启docker

```sh
    systemctl restart docker.service
```

## 启动失败处理

如果启动失败，可调用命令 `systemctl status docker.service` 查看原因。如上修改daemon.json文件后，提示错误，可能文件中的"insecure-registries"和其它配置文件冲突。查看 /lib/systemd/system/docker.service 文件，并没有配置 "insecure-registries", 继续查看 Docker 环境配置文件 /etc/default/docker，发现有段配置:

```sh
    DOCKER_OPTS="-H unix:///var/run/docker.sock -H tcp://0.0.0.0:2375 --insecure-registry 192.168.31.249"
```

将这句注释，再重启docker，就成功了。
