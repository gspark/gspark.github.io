---
title: mybatis if test判断错误处理
date: 2022-10-27 20:52:31
tags:
---

mybatis 中常用到<if test=""></if>标签进行if判断，但有时不注意写法，就会出现判断失效的情况。

## 单个字符

```xml
<if test="take == '0'">
</if>
```

这里不会进行判断。mybatis 是用 OGNL 表达式来解析的，在 OGNL 的表达式中，'0'会被解析成字符，java是强类型的，char 和 一个string 会导致不等，所以比较的结果只会是false。不会报错。可用双引号处理：

```xml
<if test='take == "0"'>
</if>
```

或者类型转换：

```xml
<if test="take == '0'.toString()">
</if>
```

## == 错写为 =

```xml
<if test="take = null">
</if>
```

这里不会进行判断。原因同上，而且 take 会赋值为 null。
