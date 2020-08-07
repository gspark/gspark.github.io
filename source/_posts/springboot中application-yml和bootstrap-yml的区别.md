---
title: springboot中application.yml和bootstrap.yml的区别
date: 2020-08-06 19:40:18
tags: Java
---

spring boot 默认支持 properties(.properties)和 YAML(.yml  .yaml ) 两种格式的配置文件。
yml 和 properties 文件都属于配置文件，它们的功能一样。
在 spring boot 框架中 bootstrap.yml 和 application.yml 都可以用来配置参数，甚至这两个文件可以同时出现。

## 配置写到 bootstrap.yml和写到 application.yml 有什么区别

### 加载顺序不一样

bootstrap.yml 先加载 application.yml 后加载。
从技术上来讲，bootstrap.yml 由父 Spring ApplicationContext 加载。父 ApplicationContext 在使用 application.yml 之前被加载。

### 应用场景不一样

#### bootstrap.yml 典型的应用场景

stackoverflow 中有个高票（301）的回答：
>I have just asked the Spring Cloud guys and thought I >should share the info I have here.
>
>bootstrap.yml **is loaded before** application.yml.
>
>It is typically used for the following:
>
>* when using Spring Cloud Config Server, you should specify spring.application.name and spring.cloud.config.server.git.uri inside bootstrap.yml
>* some encryption/decryption information
>
>Technically, bootstrap.yml is loaded by a parent Spring ApplicationContext. That parent ApplicationContext is loaded before the one that uses application.yml.

大致意思如下：

* 当使用 Spring Cloud Config Server 配置中心时，需要在 bootstrap.yml 配置文件中指定 spring.application.name 和
spring.cloud.config.server.git.uri，添加连接到配置中心的配置属性来加载外部配置中心的配置信息。
* 一些加密/解密信息

因为当使用 Spring Cloud 的时候，配置信息一般是从 config server 加载的，为了取得配置信息（比如密码等），需要一些提早的或引导配置。因此，把 config server 信息放在 bootstrap.yml，用来加载真正需要的配置信息。config server 可能做了安全认证，所以访问所需的加解密信息也需要配置在 bootstrap.yml 里。

## 属性覆盖

* 不接配置中心的情况下，启动的时候 spring boot 默认会加载 bootstrap.yml 以及 bootstrap-{profile}。{profile}在 bootstrap.yml中 spring.profiles.active 指定。
  加载顺序是： bootstrap.yml > bootstrap-{profile}.yml > application.yml >application-{profile}.yml

  如果这4个配置文件中存在相同的属性，那么后加载的属性值会覆盖掉前加载的属性值。

  **需要注意的是，有些文章说 bootstrap 不会被本地配置覆盖，如果这个说法是指 bootstrap 配置属性不会被 application 覆盖，那是错误的。**

* 在接配置中心的情况下，如果有 application.yml，它的属性值会被从配置中心中的同名属性值覆盖。

## 思考

在没有配置中心的情况下，是选择使用 bootstrap.yml 还是 application.yml，或者两者都用？
根据 bootstrap.yml 典型的应用场景，在没有配置中心的情况下，使用 bootstrap.yml 的意义不大，即使有加解密信息，将它们放到 application.yml 也是可以的。
建议在没有配置中心的情况下，去掉 bootstrap.yml 只使用 application.yml，减少配置文件，配置集中以减少出错的几率。
