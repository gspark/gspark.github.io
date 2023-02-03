---
title: oracle列表中最大表达式数为1000，mybaits解决方案
date: 2023-02-03 15:32:14
tags: mybatis
---

## 问题

在使用 mybatis 查询的时候报错：ORA-01795 列表中的最大表达式数为1000。同样的 sql 语句在 mysql 数据库没有问题，只是 oracle 数据库报此错误。这个报错信息也非常明确了，就是where in的后面带的参数太多了，超过了1000个。

## 解决方案

因为超过了1000条，那么就让in后面的参数不超过1000。将查询参数按1000进行分组，分组可以采用 guava 的 Lists.Partition 进行分组，得到`List<List<T>>`。

### 方案1：循环请求查询

查询 sql 语句不变，循环执行分组后的列表，再合并查询结果。但这种方案需要多次查询数据库，效率不高。

### 方案2：采用 or 差分 in

把in拆成多个in，用or来连接，因为or两边如果都是索引的话，索引是不会失效。以 user 表为例：

```sql
select id from user where id in(?,?,?,?.....)
--- 拆分后
select id from user where (id in(?,?,?,?.....) or id in(?,?,?,?.....)
```

maper接口修改

```java
List<LONG> selectUsers(List<List<String>> idss)
```

mapper xml 修改

```xml
<select id="selectUsers">
    select id from user where
        <foreach collection="list" item="ids" open="(" close=")" separator="or" >
            id in
            <foreach collection="ids" item="idx" open="(" close=")" separator="," >
                #{idx}
            </foreach>
        </foreach>
</select>
```

代码调整，在查询之前先对参数进行分组，然后调用 selectUsers 方法。

## 最后

推荐后一种方案，但最好执行一下执行计划，确定能够触发索引。
