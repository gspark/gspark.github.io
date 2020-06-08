---
title: Java8之Lambda表达式
date: 2020-06-01 11:05:41
tags:
---

Java 8 的最大变化是引入了 Lambda 表达式——一种紧凑的、传递行为的方式。Lambda 表达式是 Java 支持函数式编程的基础，也可以称之为`闭包`。

## 一个 Lambda 表达式

Java 8 之前排序，对 students 中的学生按照得分进行排序：

```Java
public void sort(List<Student> students) {
    students.sort(new Comparator<Student>() {
        @Override
        public int compare(Student s1, Student s2) {
            return s1.getScore() - s2.getScore();
        }
    });
}
```

在Java 8里面，可以编写更为简洁的代码，这些代码读起来更接近问题的描述：

```Java
public void sort2(List<Student> students) {
    students.sort(comparing((s) -> {
            return s.getScore();
        }));
}
```

这就是一个 Lambda 表达式，它念起来就是“给学生排序，比较得分的多少”。
上面的代码可改成：

```Java
public void sort2(List<Student> students) {
    students.sort(comparing(Student::getScore));
}
```

`::`语法 是Java 8的方法引用（即“把这个方法作为值”），比上面的写法更简洁。

## 什么是 Lambda 表达式

可以把 Lambda 表达式理解为简洁地表示可传递的匿名函数的一种方式：它没有名称，但它有参数列表、函数主体、返回类型，可能还有一个可以抛出的异常列表。

* 匿名
  它不像普通的方法那样有一个明确的名称
* 函数
  Lambda 函数不像方法那样属于某个特定的类。但和方法一样，Lambda 有参数列表、函数主体、返回类型，还可能有可以抛出的异常列表。
* 传递
  Lambda 表达式可以作为参数传递给方法或存储在变量中。简单来说，就是在 Java 语法层面允许将函数当作方法的参数，函数可以当做对象。

### Lambda 表达式的基本语法

语法格式：
(parameters) -> expression 或者 (parameters) -> { statements; }
格式理解：
(对应函数式接口的参数列表) -> { 对应函数式接口的实现方法 }

简单范例：

```Java
public void simpleLambda1() {
    Runnable runnable = () -> System.out.println("hello world");
    new Thread(runnable).start();
}
```

```Java
public void simpleLambda2() {
    new Thread(() -> {
        System.out.println("hello world");
    }).start();
}
}
```

### 函数式接口

Runnable 的定义如下：

```Java
@FunctionalInterface
public interface Runnable {
    /**
     * When an object implementing interface <code>Runnable</code> is used
     * to create a thread, starting the thread causes the object's
     * <code>run</code> method to be called in that separately executing
     * thread.
     * <p>
     * The general contract of the method <code>run</code> is that it may
     * take any action whatsoever.
     *
     * @see     java.lang.Thread#run()
     */
    public abstract void run();
}
```

可以看到 Runnable 添加了 `@FunctionalInterface` 注解，这个注解用于表示该接口会设计成一个函数式接口。表明 Runnable 接口可用作函数接口。
该注解会强制 javac 检查一个接口是否符合函数接口的标准。如果该注解添加给一个枚举类型、类或另一个注解，或者接口包含不止一个抽象方法，javac 就会报错。
重构代码时，使用它能很容易发现问题。

函数接口是只有一个抽象方法的接口，用作 Lambda 表达式的类型。任一 Lambda 表达式都有且只有一个函数式接口与之对应，从这个角度来看，也可以说是
该函数式接口的实例化。

### 引用值

java 8 之前 使用匿名内部类，也许遇到过这样的情况：需要引用它所在方法里的变量。这时，需要将变量声明为 `final`，Java 8 虽然放松了这一限制，可以
引用非 final 变量，但是该变量在既成事实上必须是 final。

Lambda 表达式中引用既成事实上的 final 变量

```Java
public void simpleLambda3() {
    String ss = "world";
    new Thread(() -> {
        System.out.println("hello " + ss);
    }).start();
}
```

如果试图给ss赋值

```Java
public void simpleLambda4() {
    String ss = "world";
    new Thread(() -> {
        System.out.println("hello " + ss);
    }).start();
    ss = "小明";
}
```

编译器报错，提示：“Variable used in lambda expression should be final or effectively final”。

## 不同形式的 Lambda 表达式

``` Java
1. Runnable noArguments = () -> System.out.println("Hello World");

2. Runnable multiStatement = () -> {
        System.out.print("Hello");
        System.out.println(" World");
   };

3. ActionListener oneArgument = event -> System.out.println("button clicked");

4. BinaryOperator<Long> addExplicit = (Long x, Long y) -> x + y;

5. BinaryOperator<Long> add = (x, y) -> x + y;
```

说明：

1. 所示的 Lambda 表达式不包含参数，使用空括号 () 表示没有参数。该 Lambda 表达式实现了 Runnable 接口，该接口也只有一个 run 方法，没有参数，
   且返回类型为 void。
2. 所示的 Lambda 表达式不包含参数，主体是一段代码块，使用大括号（{}）将代码块括起来。
   **只有一行代码的 Lambda 表达式也可使用大括号，用以明确 Lambda 表达式从何处开始、到哪里结束。**
3. 所示的 Lambda 表达式包含且只包含一个参数，可省略参数的括号。
4. 所示的 Lambda 表达式包含多个参数，并显式的声明了参数类型。这行代码并不是将两个数字相加，而是创建了一个函数，用来计算两个数字相加的结果。
5. 所示的 Lambda 表达式包含多个参数，和 4 不同的是它参数类型是编译器推导出来的
