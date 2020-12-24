---
title: Java send mail
date: 2020-12-23 17:03:52
tags: Java
---

使用 Java 发送电子邮件主要有两个方法，一个是使用 sun 公司的 mail 包，另一个是使用 SpringBoot。SpringBoot 的封装更简单。
这里简单介绍使用 SpringBoot 发送邮件的方法和使用时的注意点。

## SMTP/SMTPS 协议

SMTP（Simple Mail Transfer Protocal）称为简单邮件传输协议。SMTP 是一个请求/响应协议，它监听25号端口，用于接收用户的 Mail 请求，并与远端 Mail 服务器建立 SMTP 连接。
SMTPS（SMTP-over-SSL）为 SMTP 协议基于 SSL 安全协议之上的一种变种协议。它继承了 SSL 安全协议的非对称加密的高度安全可靠性，可防止邮件泄露。

如今绝大多数邮件服务器都使用 SMTP/SMTPS 协议。

## 引入依赖库

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-mail</artifactId>
    <version>${spring-boot.version}</version>
</dependency>
```

继续查看 spring-boot-starter-mail 的依赖树可以发现，它是对 sun 公司的 mail 包进行了封装。

## 参数配置

在 application.yml 里进行邮件发送的相关参数配置，示例如下：

```yml
spring:
  mail:
    host: mail.163.com #发送邮件服务器
    username: xxx@163.com #发送邮件的邮箱地址
    password: xxx
    from: xXx@163.com # 发送邮件的地址，和上面username一致
    to: sss@163.com
    default-encoding: utf-8
    protocol: smtps
    port: 465
    properties:
      mail:
        smtp:
          auth: true
          starttls:
            enable: true
            required: false
    test-connection: false
```

上面的配置有几个需要注意的点：

1. password 是客户端授权码，有客户端授权码填授权码，没有的话，填发送邮箱的密码。
2. protocol 需要填写。
   **邮件服务器采用 SMTPS 发送协议，protocol 的值要写成 smtps；如果采用 SMTP，则要写成 smtp。**
3. port 的键是 spring.mail.port
   **有些文章将 port 的键写成了 spring.mail.properties.mail.smtp.port，这可能是 SpringBoot 的版本原因，注意区分。**

## 封装接口实现发送

封装 Service 实现邮件发送，一个简单的示例如下:

```Java
@Service
public class MailService {

    @Value("${spring.mail.username}")
    private String from;

    @Value("${spring.mail.to:}")
    private String to;

    @Autowired
    private JavaMailSender javaMailSender;

    /**
     * 发送文本邮件
     *
     * @param to      收件人
     * @param subject 主题
     * @param content 内容
     */
    public void sendTextMail(String to, String subject, String content) {
        SimpleMailMessage message = new SimpleMailMessage();
        // 发送对象
        if (null != to && to.length() > 0) {
            if (to.indexOf(",") > 0) {
                message.setTo(to.split(","));
            } else {
                message.setTo(to);
            }
        } else {
            message.setTo(from);
        }

        // 邮件主题
        message.setSubject(subject);
        // 邮件内容
        message.setText(content);
        // 邮件的发起者
        message.setFrom(from);

        try {
            javaMailSender.send(message);
        } catch (org.springframework.mail.MailSendException e) {
            log.error("error:" + from, e);
        }
    }
}
```

注入 JavaMailSender，JavaMailSender 实现了邮件发送。上例是发送文本邮件，可发送多个人。
