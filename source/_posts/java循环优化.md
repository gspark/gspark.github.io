---
title: java循环优化
date: 2020-04-23 16:00:03
tags: Java
---

在许多应用程序中，循环都扮演着非常重要的角色。为了提升循环的运行效率，研发编译器的工程师提出了不少面向循环的编译优化方式，如循环无关代码外提，循环
展开等。

今天，我们便来了解一下，Java 虚拟机中的即时编译器都应用了哪些面向循环的编译优化。

## 循环外提

所谓的循环无关代码（Loop-invariant Code），指的是循环中值不变的表达式。如果能够在不改变程序语义的情况下，将这些循环无关代码提出循环之外，那么
程序便可以避免重复执行这些表达式，从而达到性能提升的效果。

例子：

```Java
    public int loop1(int x, int y, int[] ary) {
        int sum = 0;
        for (int i = 0; i < ary.length; i++) {
            sum += x * y + ary[i];
        }
        return sum;
    }
```

对应字节码

```Java
 public int loop1(int, int, int[]);
    descriptor: (II[I)I
    flags: ACC_PUBLIC
    Code:
      stack=4, locals=6, args_size=4
         0: iconst_0
         1: istore        4
         3: iconst_0
         4: istore        5
         // 循环开始
         6: iload         5
         8: aload_3
         9: arraylength         // ary.length
        10: if_icmpge     32    // i < ary.length
        13: iload         4
        15: iload_1
        16: iload_2
        17: imul                // x*y
        18: aload_3
        19: iload         5
        21: iaload              // ary[i]
        22: iadd
        23: iadd
        24: istore        4
        26: iinc          5, 1
        29: goto          6
        // 循环结束
        32: iload         4
        34: ireturn
```

在上面这段代码中，循环体中的表达式x*y，以及循环判断条件中的ary.length均属于循环不变代码。
前者是一个整数乘法运算，而后者则是内存访问操作，读取数组对象ary的长度。（数组的长度存放于数组对象的对象头中，可通过 arraylength 指令来访问。）

理想情况下，上面这段代码经过循环无关代码外提之后，等同于下面这一手工优化版本。

```Java
    public int loop1Opt(int x, int y, int[] ary) {
        int sum = 0;
        int t0 = x * y;
        int t1 = ary.length;
        for (int i = 0; i < t1; i++) {
            sum += t0 + ary[i];
        }
        return sum;
    }
```

对应字节码

```Java
  public int loop1Opt(int, int, int[]);
    descriptor: (II[I)I
    flags: ACC_PUBLIC
    Code:
      stack=4, locals=8, args_size=4
         0: iconst_0
         1: istore        4
         3: iload_1
         4: iload_2
         5: imul
         6: istore        5
         8: aload_3
         9: arraylength
        10: istore        6
        12: iconst_0
        13: istore        7
        // 循环开始
        15: iload         7
        17: iload         6
        19: if_icmpge     40
        22: iload         4
        24: iload         5
        26: aload_3
        27: iload         7
        29: iaload          // ary[i]
        30: iadd
        31: iadd
        32: istore        4
        34: iinc          7, 1
        37: goto          15
        // 循环结束
        40: iload         4
        42: ireturn
```

我们可以看到，无论是乘法运算x*y，还是内存访问ary.length，现在都在循环之前完成。原本循环中需要执行这两个表达式的地方，现在直接使用循环之前这两个表达式的执行结果。

java的JIT实现了循环无关代码的外提。

即时编译器JIT还外提了 int 数组加载指令iaload所暗含的 null 检测（null check）以及下标范围检测（range check）。
如果将iaload指令想象成一个接收数组对象以及下标作为参数，并且返回对应数组元素的方法，那么它的伪代码大致如下所示：

```Java
    public int iaload(int[] aryRef, int index) {
        if (aryRef == null) {
            // null 检测
            throw new NullPointerException();
        }
        if (index < 0 || index >= aryRef.length) {
            // 下标范围检测
            throw new ArrayIndexOutOfBoundsException();
        }
        return aryRef[index];
    }
```

loop1 方法中的 null 检测属于循环无关代码。这是因为它始终检测作为输入参数的 int 数组是否为 null，而这与第几次循环无关。

为了更好地阐述具体的优化，修改了原来的例子，并将iaload展开，形成如下所示的代码：

```Java
    public int loop1(int[] a) {
        int sum = 0;
        for (int i = 0; i < a.length; i++) {
            if (a == null) {
                // null check
                throw new NullPointerException();
            }
            if (i < 0 || i >= a.length) {
                // range check
                throw new ArrayIndexOutOfBoundsException();
            }
            sum += a[i];
        }
        return sum;
    }
```

在上面的代码段中，null 检测涉及了控制流依赖，无法完成外提。

在 HotSpot VM的C2编译器 中，null 检测的外提是通过额外的编译优化，也就是循环预测（Loop Prediction，对应虚拟机参数-XX:+UseLoopPredicate）来实现的。该优化的实际做法是在循环之前插入同样的检测代码，并在命中的时候进行去优化。这样一来，循环中的检测代码便会被归纳并消除掉。

```Java
    public int loop2(int[] a) {
        int sum = 0;
        if (a == null) {
            deoptimize(); // never returns
        }

        for (int i = 0; i < a.length; i++) {
            if (a == null) {
                // now evluate to false
                throw new NullPointerException();
            }
            if (i < 0 || i >= a.length) {
                // range check
                throw new ArrayIndexOutOfBoundsException();
            }
            sum += a[i];
        }
        return sum;
    }
```

## 循环展开

另外一项非常重要的循环优化是循环展开（Loop Unrolling）。它指的是在循环体中重复多次循环迭代，并减少循环次数的编译优化。

```Java
    public int loop3(int[] ary) {
        int sum = 0;
        for (int i = 0; i < 64; i++) {
            sum += (i % 2 == 0) ? ary[i] : -ary[i];
        }
        return sum;
    }
```

上面的代码经过一次循环展开之后将形成下面的代码：

```Java
    public int loop3Opt(int[] ary) {
        int sum = 0;
        for (int i = 0; i < 64; i += 2) {
            // 注意这里的步数是 2
            sum += (i % 2 == 0) ? ary[i] : -ary[i];
            sum += ((i + 1) % 2 == 0) ? ary[i + 1] : -ary[i + 1];
        }
        return sum;
    }
```

循环展开的缺点显而易见：它可能会增加代码的冗余度，导致所生成机器码的长度大幅上涨。

不过，随着循环体的增大，优化机会也会不断增加。一旦循环展开能够触发进一步的优化，总体的代码复杂度也将降低。比如前面的例子经过循环展开之后便可以进一步优化为如下所示的代码：

```Java
    public int loop3Opt1(int[] ary) {
        int sum = 0;
        for (int i = 0; i < 64; i += 2) {
            sum += ary[i];
            sum += -ary[i + 1];
        }
        return sum;
    }
```

## 其他循环优化

除了循环无关代码外提以及循环展开之外，即时编译器还有两个比较重要的循环优化技术：循环判断外提（loop unswitching）以及循环剥离（loop peeling）。

### 循环判断外提

指的是将循环中的 if 语句外提至循环之前，并且在该 if 语句的两个分支中分别放置一份循环代码。

```Java
    public int loop4(int[] ary) {
        int sum = 0;
        for (int i = 0; i < ary.length; i++) {
            if (ary.length > 4) {
                sum += ary[i];
            }
        }
        return sum;
    }
```

上面这段代码经过循环判断外提之后，将变成下面这段代码：

```Java
    public int loop4Opt(int[] ary) {
        int sum = 0;
        if (ary.length > 4) {
            for (int i = 0; i < ary.length; i++) {
                sum += ary[i];
            }
        } else {
            for (int i = 0; i < ary.length; i++) {
            }
        }
        return sum;
    }
}
```

进一步优化

```Java
    public int loop4Opt1(int[] ary) {
        int sum = 0;
        if (ary.length > 4) {
            for (int i = 0; i < ary.length; i++) {
                sum += ary[i];
            }
        }
        return sum;
    }
```

循环判断外提与循环无关检测外提所针对的代码模式比较类似，都是循环中的 if 语句。不同的是，后者在检查失败时会抛出异常，中止当前的正常执行路径；而前者所针对的是更加常见的情况，即通过 if 语句的不同分支执行不同的代码逻辑。

### 循环剥离

指的是将循环的前几个迭代或者后几个迭代剥离出循环的优化方式。一般来说，循环的前几个迭代或者后几个迭代都包含特殊处理。通过将这几个特殊的迭代剥离出去，可以使原本的循环体的规律性更加明显，从而触发进一步的优化。

```Java
    public int loop5(int[] ary) {
        int j = 0;
        int sum = 0;
        for (int i = 0; i < ary.length; i++) {
            sum += ary[j];
            j = i;
        }
        return sum;
    }
```

上面这段代码剥离了第一个迭代后，将变成下面这段代码：

```Java
    public int loop5Opt(int[] ary) {
        int sum = 0;
        if (null != ary && 0 < ary.length) {
            sum += ary[0];
            for (int i = 1; i < ary.length; i++) {
                sum += ary[i - 1];
            }
        }
        return sum;
    }
```

## 转自

极客时间 -《循环优化》
