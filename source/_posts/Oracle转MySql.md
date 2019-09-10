---
title: Oracle转MySql
date: 2019-09-10 10:56:52
tags:
---

最近产品要支持MySQl数据库，从Oracle转MySql，记录过程，用以备忘。

## 手动转换

手动方式，就是操作步骤会比较繁琐一些。
对 Table 的结构和数据：

1. 使用 SQL Developer 把 oracle 的 table 的schema 和 Data（.sql 和 .xls） 导出
2. 使用 MySQL 的 WorkBench 创建 Table 和导入数据。
由于语法和数据类型会稍微有一些不同，需要做一些调整。
对于 View 来说， 特别是复杂的有子查询的 Oracle View 说，要导入到 MySQL 不是那么容易了，基本上都需要重写。

## 使用工具 Navicat

试了好几个工具，只有 Navicat 最方便，不仅能导入表结构，还能导入注释。视图和存储过程要手动导入。

1. 创建 MySql 数据库。
2. 启动 Navicat，选择`工具`菜单下的`数据传输`子菜单。
3. 在数据传输对话窗体的`常规`标签页选择源和目标。这里源选择 Oracle 数据库，目标选择 MySQL 数据库。在`选项`标签页，找到`遇到错误继续`，根据情况设置是否勾选。
4. 点击`下一步`，在接下来的`数据库对象`页签选择表（Oracle转MySQl，只能选择表）。
5. 点击`开始`等待执行结果。
6. 手动导入存储过程和视图。由于语法不一样，sql语句需要改写。

## MySQL5转MySQL8

MySQL5转MySQL8相对比较简单，手动转或者用Navicat转都不复杂，Navicat 还可以导入存储过程和视图。只是 mysql8.0.1 之后的默认 COLLATE 为utf8mb4_0900_ai_ci，如果在转换的时候没注意的话，可能出现 `java.sql.SQLException: Illegal mix of collations (utf8mb4_general_ci,IMPLICIT) and (utf8mb4_0900_ai_ci,IMPLICIT) for ***` 样的错误。解决方案如下：

1. MySQL8建库时，编码选 utf8mb4，COLLATE选 utf8mb4_0900_ai_ci。utf8mb4_unicode_ci和utf8mb4_general_ci对于中文和英文来说，其实没什么太大区别。对于我们开发的国内使用的系统来说，随便选哪个都行。utf8mb4_0900_ai_ci大体上就是unicode的进一步细分，0900指代unicode比较算法的编号（ Unicode Collation Algorithm version），ai表示accent insensitive（发音无关），例如e, è, é, ê 和 ë是一视同仁的。所以选 utf8mb4_0900_ai_ci 没什么问题。
2. 采用Navicat导入时，在“数据传输”的`选项`里，注意不要勾选`包含字符集`。

## linux 下 MySQL 重启

由于是从源码包安装的Mysql，所以系统中是没有红帽常用的`servcie mysqld restart`这个脚本，如果没有自建脚本，只好手工重启。采用 Killall mysql，可能会损害数据库。安全重启的方法如下：

```sh
$mysql_dir/bin/mysqladmin -u root -p shutdown
$mysql_dir/bin/safe_mysqld &
```

mysqladmin和mysqld_safe位于Mysql安装目录的bin目录下。
