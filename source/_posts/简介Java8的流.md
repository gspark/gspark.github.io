---
title: 简介Java8的流
date: 2020-06-08 20:12:45
tags:
---

流是Java API的新成员，它允许以`声明性`方式处理数据集合（通过查询语句来表达，而不是临时编写一个实现）。
流还可以透明地并行处理，无需编写任何多线程代码了。

## 使用流的例子

下面两段代码都是用来返回成绩好的学生的姓名，并按照得分排序，一个是用Java 7写的，另一个是用Java 8的流写的。

Java7

```Java
public void studentNames() {
    List<Student> goodStudents = new ArrayList<>();
    for (Student d : students) {
        if (d.getScore() >= GOOD) {
            goodStudents.add(d);
        }
    }
    goodStudents.sort(new Comparator<Student>() {
        public int compare(Student d1, Student d2) {
            return Integer.compare(d1.getScore(), d2.getScore());
        }
    });
    List<String> goodStudentNames = new ArrayList<>();
    for (Student d : goodStudents) {
        goodStudentNames.add(d.getName());
    }
    System.out.println(goodStudentNames);
}
```

Java8采用流的代码：

```Java
public void studentNamesJ8() {
    List<String> goodStudentNames = students.stream()
        .filter(s -> s.getScore() >= GOOD)
        .sorted(comparing(Student::getScore))
        .map(Student::getName)
        .collect(Collectors.toList());

    System.out.println(goodStudentNames);
}
```

为了利用多核架构并行执行这段代码，只需要把stream()换成parallelStream():

```Java
public void studentNamesJ8() {
    List<String> goodStudentNames = students.parallelStream()
        .filter(s -> s.getScore() >= GOOD)
        .sorted(comparing(Student::getScore))
        .map(Student::getName)
        .collect(Collectors.toList());

    System.out.println(goodStudentNames);
}
```

采用流方法的好处:

* 声明性方式
  说明想要完成什么（筛选成绩好的学生）而不是说明如何实现（循环和if条件等控制流语句）。
* 代码清晰易读
  把几个基础操作链接起来，来表达复杂的数据处理流水线。filter 的结果被传给了 sorted 方法，再传给 map 方法，最后传给 collect 方法。
* 可轻松利用多核
  只需把stream()换成parallelStream()。

## 流是什么

Java 8中的集合支持一个新的 stream 方法，它会返回一个流（接口定义在java.util.stream.Stream里）。还有很多其他的方法可以得到流，
比如利用数值范围或从I/O资源生成流元素。流的简短定义就是“从支持数据处理操作的源生成的元素序列”。
进一步说明这个定义：

* 元素序列
  就像集合一样，流也提供了一个接口，可以访问特定元素类型的一组有序值。但流的目的在于表达计算，比如前面见到的 filter、sorted 和 map。
  与集合不同地方是集合讲的是数据，流讲的是计算。
* 源
  流会使用一个提供数据的源，如集合、数组或输入/输出资源。
* 数据处理操作
  流的数据处理功能支持类似于数据库的操作，以及函数式编程语言中的常用操作，如filter、map、reduce、find、match、sort等。流操作可以
  顺序执行，也可并行执行。

此外，流还有两个重要特点：

* 流水线
  很多流操作本身会返回一个流，这样多个操作就可以链接起来，形成一个大的流水线。
* 内部迭代
  流的迭代操作是在背后进行的。

一段体现这些概念的代码示例：

```Java
public void studentNamesLimit() {
    List<String> goodStudentNames = students.stream()
        .filter(s -> s.getScore() >= GOOD)
        .sorted(comparing(Student::getScore))
        .map(Student::getName)
        .limit(3)
        .collect(Collectors.toList());

    System.out.println(goodStudentNames);
}
```

在本例中，我们先是对 students 调用 stream 方法，由学生列表得到一个流。数据源是学生列表，它给流提供一个元素序列。
接下来，对流应用一系列数据处理操作：filter、sorted、map、limit 和 collect。
除了 collect 之外，所有这些操作都会返回另一个流，这样它们就可以接成一条流水线，于是就可以看作对源的一个查询。
最后，collect 操作开始处理流水线，并返回结果（它和别的操作不一样，因为它返回的不是流，在这里是一个 List ）。
在调用 collect 之前，没有任何结果产生，实际上根本就没有从 students 里选择元素。你可以这么理解：链中的方法调用都在排队等待，直到调用collect。

在这里我们并没有去实现筛选（filter）、排序（sorted）、提取（map）或截断（limit）功能，Streams库已经自带了。

## 流与集合

Java 现有的集合和新的流都提供了接口，来配合代表元素型有序值的数据接口。所谓有序，就是说我们一般是按顺序取用值，而不是随机取用的。
集合与流之间的差异就在于什么时候进行计算。集合是一个内存中的数据结构，它包含数据结构中目前所有的值 —— 集合中的每个元素都得先算出来才能添加到集合中。
（可以往集合里加东西或者删东西，但是不管什么时候，集合中的每个元素都是放在内存里的，元素都得先算出来才能成为集合的一部分。）相比之下，
流则是在概念上固定的数据结构（不能添加或删除元素），其元素则是按需计算的。这是一种生产者－消费者的关系。从另一个角度来说，流就像是一个
延迟创建的集合：只有在消费者要求的时候才会计算值（用管理学的话说这就是需求驱动，甚至是实时制造)。

流只能遍历一次，遍历完了后，遍历完之后，我们就说这个流已经被消费掉了。例如，以下代码会抛出一个异常，说流已被消费掉了：

```Java
List<String> title = Arrays.asList("Java8", "Stream", "Example");
Stream<String> s = title.stream();
s.forEach(System.out::println);
s.forEach(System.out::println);
```

输出：

```sh
Java8
In
Action
Exception in thread "main" java.lang.IllegalStateException: stream has already been operated upon or closed
```

## 流操作

可以连接起来的流操作称为中间操作，关闭流的操作称为终端操作。
诸如 filter 或 sorted 等中间操作会返回另一个流。这让多个操作可以连接起来形成一个查询。重要的是，除非流水线上触发一个终端操作，
否则中间操作不会执行任何处理。这是因为中间操作一般都可以合并起来，在终端操作时一次性全部处理。看一个例子，在每个 Lambda 都打印当前处理的学生名：

```Java
List<String> goodStudentNames = students.stream()
    .filter(s -> {
        System.out.println("filter-> " + s.getName());
        return s.getScore() >= GOOD;
    })
    .map(s -> {
        System.out.println("map-> " + s.getName());
        return s.getName();
    })
    .limit(3)
    .collect(toList());

System.out.println(goodStudentNames);
```

输出结果：

```Java
filter-> tom
filter-> jerry
filter-> 小李
map-> 小李
filter-> 小张
map-> 小张
filter-> 小明
filter-> 大熊
filter-> 小雨
filter-> 二狗
map-> 二狗
[小李, 小张, 二狗]
```

可以看到 filter 的操作次数没有列表那么长，说明 filter 和 map 的操作有合并。
