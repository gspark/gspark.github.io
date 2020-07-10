---
title: Java之happens-before
date: 2020-05-26 16:10:28
tags:
---

## 从一个例子开始

```Java
public class MemModle {
    private int a = 0;
    private int b = 0;

    public void method1() {
        int m2 = a;
        b = 1;
    }

    public void method2() {
        int m1 = b;
        a = 2;
    }
}
```

在单线程的情况下，如果先执行 method1 再执行 method2，最终 m1，m2 为 1， 0；如果先执行 method2 再执行 method1，最终 m1，m2 为 0， 2。
在多线程的情况下，假设这两个方法分别在不同的线程执行，如果 Java 虚拟机在执行了任一方法的第一条赋值语句后就切换线程，那么 m1，m2 的最终结果可能就是
0，0 了。除了上面三种情况外，m1，m2 的结果还有一种情况出现：1，2。

造成这种看似不可能的结果的原因有 3 个：

* 即时编译器的重排序
* 处理器的乱序执行
* 内存系统的重排序

后面两种原因涉及到具体的体系架构，这里不做探讨。

## 即时编译器的重排序

即时编译器(和处理器)需要保证程序能够遵守 `as-if-serial` 属性。`as-if-serial` 语义是：不管怎么重排序（编译器和处理器为了提高并行度），
（单线程）程序的执行结果不能被改变。编译器、runtime 和处理器都必须遵守 `as-if-serial` 语义。
通俗的讲，在单线程的情况下，要给程序一个顺序执行的假象，即经过重排序的执行结果要和顺序执行的结果一致。
此外，如果两个操作之间存在数据依赖，那么即时编译器(和处理器)不能调整它们的执行顺序，否则会造成程序语义的变化。

## Java 内存模型与 happens-before

Java 5 引入了明确定义的 Java 内存模型，其中最为重要的一个概念就是 happens-before 关系。happens-before 关系是用来描述两个操作的内存可见性的。
它定义了内存的可见性原则。如果一个操作 happens-before 另一个操作， 那么第一个操作的结果对第二个结果可见。

### 规则

下面是Java内存模型中的八条可保证 happen—before 的规则，它们无需任何同步器协助就已经存在，可以在编码中直接使用。
如果两个操作之间的关系不在此列，并且无法从下列规则推导出来的话，它们就没有顺序性保障，虚拟机可以对它们进行随机地重排序。

* 单线程规则
  在一个单独的线程中，执行结果与按照程序代码的执行顺序的结果是一致的。
* 锁定规则
  一个 解锁 操作 happen—before 之后对同一个锁的 加锁 操作。
* volatile 变量规则
  对一个 volatile 变量的写操作 happen—before 之后对该变量的读操作。
* 线程启动规则
  Thread 对象的 start() happen—before 该线程的第一个操作。
* 线程结束规则
  线程的最后一个操作 happen—before 它的终止事件（即其它线程通过Thread.isAlive()或者Thread.join() 判断该线程是否终止）。
* 中断规则
  线程对其它线程的中断操作 happen—before 被中断线程所收到的中断时事件（被中断线程的 InterruptedException 异常或者Thread.interrupted 调用）。
* 终结器规则
  构造器中的最后一个操作 happen—before 析构器的第一个操作。
* 传递性规则
  happens-before 关系具备传递性，如果操作 A happens-before 操作 B， 而操作 B happens-before 操作 C，那么 操作 A happens-before 操作 C。

在开头的例子中，程序没有定义任何 happens-before 关系，仅拥有默认线程内 happens-before 关系，也就是 m2 的赋值操作 happens-before b 的
赋值操作，m1的赋值操作 happens-before a 的赋值操作。拥有 happens-before 关系的两对赋值操作之间没有数据依赖，因此即时编译器（处理器）都可能
对其进行重排序。如下：

``` java
thread1    thread2
   |          |
  m2=a       m1=b
  b=1        a=2
   |          |
   |          |
```

重排后

``` java
thread1    thread2
   |          |
  b=1         |
   |          m1=b
   |          a=2
  m2=a        |
```

只要将 b 的赋值操作排在 m2 的赋值操作之前，那么就可以 1，2 的结果。

那么怎么解决这个问题呢？将 a 或者 b 设置为 volatile 字段。

比如将 b 设置为 volatile 字段。根据 volatile 字段的 happens-before 规则，我们知道 b 的写（赋值）操作 happens-before m1 的赋值操作。
在没有标记 volatile 的时候，同一线程中，m2=a和b=1存在happens before关系，但因为没有数据依赖可以重排列。一旦标记了volatile，即时编译器和CPU需要考虑到多线程happens-before关系，因此不能自由地重排序。

``` java
thread1    thread2
   |          |
  m2=a        |
  b=1         |
   |          m1=b
   |          a=2
```

也就意味着，当对 a 进行赋值的时候，对 m2 的赋值操作已经完成。因此，在 b 为 volatile 字段的情况下，不会出现 m1，m2 出现 1， 2 的情况。

## 内存模型的实现

Java 内存模型是通过内存屏障（Memory Barrier）来禁止指令重排序的。
对于即时编译器来说，它会根据 happens-before 规则，向正在编译的目标方法中插入相应的读读、读写、写读和写写内存屏障。
这些内存屏障会限制即时编译器的重排序操作。以 volatile 字段访问为例，所插入的内存屏障将不允许 volatile 字段 写操作 之前的内存访问被重排序至其之后；
也将不允许 volatile 字段 读操作 之后的内存访问被重排序至其之前。

然后，即时编译器将根据具体的底层体系架构，将这些内存屏障替换成具体的 CPU 指令。以我们日常接触的 X86_64 架构来说，读读、读写以及写写内存屏障是
空操作（no-op），只有写读内存屏障会被替换成具体指令。

## 锁，final 字段

### 锁

锁操作同样具备 happens-before 关系。解锁操作 happens-before 之后对同一把锁的加锁操作。实际上，在解锁时，Java 虚拟机同样需要强制
刷新缓存，使得当前线程所修改的内存对其它线程可见。需要注意的是，锁操作的 happens-before 规则的关键字是同一把锁。也就意味着，如果编译器能够
证明某把锁仅被同一线程持有，那么它可以移除相应的加锁解锁操作。
因此也就不再强制刷新缓存。举个例子，即时编译后的 `synchronized (new Object()) {}`，可能等同于空操作，而不会强制刷新缓存。

### final 字段

final 实例字段则涉及新建对象的发布问题。当一个对象包含 final 实例字段时，我们希望其他线程只能看到已初始化的 final 实例字段。

因此，即时编译器会在 final 字段的写操作后插入一个写写屏障（StoreStore屏障），以防某些优化将新建**对象的发布**（即将实例对象写入一个共享引用中）重排序至 final 字段的
写操作之前。在 X86_64 平台上，写写屏障（StoreStore屏障）是空操作。
具体来说对于final域，编译器和处理器要遵守两个重排序规则：

* 在构造函数内对一个final域的写入，与随后把这个被构造对象的引用赋值给一个引用变量，这两个操作之间不能重排序。
* 初次读一个包含final域的对象的引用，与随后初次读这个final域，这两个操作之间不能重排序。

```Java
public class MemModle1 {

    int i;                            //普通变量
    final int j;                      //final变量
    static MemModle1 obj;

    public MemModle1() {
        i = 1;                        //写普通域
        j = 2;                        //写final域
    }

    public static void writer() {    //写线程A执行
        obj = new MemModle1();
    }

    public static void reader() {       //读线程B执行
        MemModle1 object = obj;       //读对象引用
        int a = object.i;                //读普通域
        int b = object.j;                //读final域
    }
}
```

## 引用

极客时间 -《Java内存模型》
