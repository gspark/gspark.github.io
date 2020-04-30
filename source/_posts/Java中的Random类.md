---
title: Java中的Random类
date: 2020-04-29 16:01:06
tags: Java
---

## 前言

Java中生成随机数的方式有很多，Math.Random()、Random、ThreadLocalRandom、SecureRandom类等。不同的类和方法适用的产生随机数的场景也不一样。
伪随机数是用确定性的算法计算出来自[0,1]均匀分布的随机数序列。并不真正的随机，但具有类似于随机数的统计特征，如均匀性、独立性等。在计算伪随机数时，若
使用的初值（种子）不变，那么伪随机数的数序也不变。

## Math.Random()

Math.Random()函数能够返回带正号的double值，该值大于等于0.0且小于1.0，即取值范围是[0.0,1.0)的左闭右开区间，返回值是一个伪随机选择的数，在该
范围内（近似）均匀分布。例子如下：

```Java
    public static void mathRandom() {
        System.out.println("Math.random()=" + Math.random());
        int num = (int) (Math.random() * 3);
        System.out.println("num=" + num);
    }
```

输出

```Java
    Math.random()=0.8890842451831729
    num=2
```

## Random类

Random类有两种构造方法：

* Random()
  使用系统计时器的当前值作为随机种子来构建Random对象
* Random(long seed)
  使用指定 long 种子来构建Random对象

创建一个Random对象的时候可以给定任意一个合法的种子数，种子数只是随机算法的起源数字，和生成的随机数的区间没有任何关系。

```Java
    Random rand =new Random(10);
    int i;
    i=rand.nextInt(100);
```

初始种子为10，它对产生的随机数的范围并没有起作用,`rand.nextInt(100);`中的100是随机数的上限,产生的随机数为0-100的整数,不包括100。

### 对于种子相同的Random对象，生成的随机数序列是一样的

例子：

```Java
    Random ran1 = new Random(8);
    System.out.println("使用种子为8的Random对象生成[0,10)内随机整数序列: ");
    for (int i = 0; i < 10; i++) {
        System.out.print(ran1.nextInt(10) + " ");
    }

    System.out.println();
    Random ran2 = new Random(8);
    System.out.println("使用另一个种子为8的Random对象生成[0,10)内随机整数序列: ");
    for (int i = 0; i < 10; i++) {
        System.out.print(ran2.nextInt(10) + " ");
    }
```

输出：

```Java
    使用种子为8的Random对象生成[0,10)内随机整数序列:
    4 6 0 1 2 8 1 1 3 0
    使用另一个种子为8的Random对象生成[0,10)内随机整数序列:
    4 6 0 1 2 8 1 1 3 0
```

### 相同的Random对象，多次调用nextInt生成的随机数序列会不同

例子：

```Java
    Random ran2 = new Random(8);
    System.out.println("使用另一个种子为8的Random对象生成[0,10)内随机整数序列: ");
    for (int i = 0; i < 10; i++) {
        System.out.print(ran2.nextInt(10) + " ");
    }
    System.out.println();
    System.out.println("使用同一个种子为8的Random对象生成[0,10)内随机整数序列: ");
    for (int i = 0; i < 10; i++) {
        System.out.print(ran2.nextInt(10) + " ");
    }
```

输出：

```Java
    使用另一个种子为8的Random对象生成[0,10)内随机整数序列:
    4 6 0 1 2 8 1 1 3 0
    使用同一个种子为8的Random对象生成[0,10)内随机整数序列:
    4 0 2 7 8 8 2 9 3 5
```

### 不同的Random对象，采用默认构造函数，生成的随机数序列不一样

例子：

```Java
    Random r3 = new Random();
    System.out.println();
    System.out.println("使用种子缺省是当前系统时间的Random对象生成[0,10)内随机整数序列");
    for (int i = 0; i < 10; i++) {
        System.out.print(r3.nextInt(10) + " ");
    }

    Random r4 = new Random();
    System.out.println();
    System.out.println("使用种子缺省是当前系统时间的Random对象生成[0,10)内随机整数序列");
    for (int i = 0; i < 10; i++) {
        System.out.print(r4.nextInt(10) + " ");
    }
```

输出：

```Java
    使用种子缺省是当前系统时间的Random对象生成[0,10)内随机整数序列
    7 6 6 1 1 5 4 3 3 5
    使用种子缺省是当前系统时间的Random对象生成[0,10)内随机整数序列
    2 6 2 3 1 1 5 2 8 1
```

### "Random" objects should be reused

Sonar 的代码审查提出“For better efficiency and randomness, create a single Random, then store, and reuse it.”，主要原因是：

* 创建Random是有代价的，如下面的例子：

```Java
    public static int getRandom(int bound) {
        Random ran = new Random();
        return ran.nextInt(bound);
    }
```

getRandom每次调用都会构造一个新的Random对象，效率不高。

* 随机性不够好，如下面例子：

```Java
    public static int getRandom(int bound) {
        Random ran = new Random(8);
        return ran.nextInt(bound);
    }
```

这样多次调用getRandom可能得到的值都是一样的，随机性不够好。其实这也是一种随机，只是均匀性，对立性不够了。

但是如果不需要频繁的获取平均数，将Random对象存储起来，可能会造成Random对象不能被gc，也会造成浪费。

### 线程安全性

Random是一个线程安全类，理论上可以通过它同时在多个线程中获得互不相同的随机数，但是它会因为多线程竞争同一个seed而造成性能下降，所以建议在多线程的
情况下采用ThreadLocalRandom来产生随机数。

Random在执行`nextInt`时，会调用`next`函数，代码如下：

```Java
    protected int next(int bits) {
        long oldseed, nextseed;
        AtomicLong seed = this.seed;
        do {
            oldseed = seed.get();
            nextseed = (oldseed * multiplier + addend) & mask;
        } while (!seed.compareAndSet(oldseed, nextseed));
        return (int)(nextseed >>> (48 - bits));
    }
```

由于seed的类型是AtomicLong，在计算nextseed时是原子操作，所以没有线程安全性的问题。

### SecureRandom

Random类只要种子一样，产生的随机数也一样： 因为种子确定，随机数算法也确定，因此输出就是确定的。

* SecureRandom提供加密的强随机数生成器 (RNG)，要求种子必须是不可预知的，可产生非确定性输出
* SecureRandom许多实现都是伪随机数生成器 (PRNG) 形式，这意味着它们将使用确定的算法根据实际的随机种子生成伪随机序列
* SecureRandom和Random都是如果种子一样，产生的随机数也一样： 因为种子确定，随机数算法也确定，因此输出是确定的。
  SecureRandom类收集了一些随机事件，比如鼠标点击，键盘点击等等，SecureRandom 使用这些随机事件作为种子。这意味着，种子是不可预测的，而不像Random默认使用系统当前时间的毫秒数作为种子，有规律可寻。

不当用法：

```Java
    byte[] salt = new byte[128];
    SecureRandom secureRandom = new SecureRandom();
    secureRandom.setSeed(System.currentTimeMillis());  //使用系统时间作为种子
    secureRandom.nextBytes(salt);
```

例子中指定了当前系统时间作为种子，替代系统默认随机源。如果同一毫秒连续调用，则得到的随机数则是相同的。

系统默认的随机源取决于$JAVA_HOME/jre/lib/security/java.security配置中的securerandom.source属性。例如jdk1.8中该配置为：

```sh
securerandom.source=file:/dev/random
```

SecureRandom内置两种随机数算法，NativePRNG和SHA1PRNG，看实例化的方法了。默认来说会使用NativePRNG算法生成随机数。

一般来说尽量避免指定任何随机生成器，只需调用空参数构造函数：`new SecureRandom()`，让系统选择最好的随机数生成器。
