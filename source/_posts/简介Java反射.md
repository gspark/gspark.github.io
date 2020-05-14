---
title: 简介Java反射
date: 2020-05-08 14:44:41
tags:
---

在介绍 Java 的反射之前，先对类对象、类加载做个简单说明，大概可以了解 Java 反射的基本原理。

## 类文件、类对象和元数据

* 类文件是编译 Java 源码文件（也可能是其他语言的源码文件）得到的中间格式，供 JVM 使用。类文件是二进制文件，目的不是供人类阅读。
* 运行时通过包含元数据的类对象（Class 对象）表示类文件，而类对象表示的是从中创建类文件的 Java 类型。
  Class 对象保存了类相关的类型信息，当 new 一个新的对象或者引用静态成员变量时，JVM的类加载器会将
  对应 Class 对象加载在 JVM 中，然后 JVM 再根据这个类型信息相关的 Class 对象构造实例对象或者提供静态变量的引用值。

在 Java 中，获取类对象有多种方式。其中最简单的方式是：

```Java
Class<?> myCl = getClass();
```

上述代码返回调用 getClass() 方法的实例对应的类对象。

* 类对象包含指定类型的元数据，包括这个类中定义的方法、字段和构造方法等。
例如，可以找出类文件中所有的弃用方法（弃用方法使用 @Deprecated 注解标记）：

```Java
Class<?> clz = getClassFromDisk();
for (Method m : clz.getMethods()) {
  for (Annotation a : m.getAnnotations()) {
    if (a.annotationType() == Deprecated.class) {
      System.out.println(m.getName());
    }
  }
}
```

类文件必须符合非常明确的布局才算合法，JVM 才能加载。

## 类加载

类加载是把新类型添加到运行中的 JVM 进程里的过程。这是新代码进入 Java 系统的唯一方式，也是 Java 平台中把数据变成代码的唯一方式。
Java 的类加载子系统实现了很多安全功能。类加载架构的核心安全机制是，只允许使用一种方式把可执行的代码传入进程——类。
因为创建新类只有一种方式，即使用 Classloader 类提供的功能，从字节流中加载类。

## 反射

反射是在运行时审查、操作和修改对象的能力，可以修改对象的结构和行为，甚至还能自我修改。

即便编译时不知道类型和方法名称，也能使用反射。反射使用类对象提供的基本元数据，能从类对象中找出方法或字段的名称，然后获取表示方法或字段的对象。

（使用 Class::newInstance() 或另一个构造方法）创建实例时也能让实例具有反射功能。如果有一个能反射的对象和一个 Method 对象，我们就能在之前
类型未知的对象上调用任何方法。

### 如何使用反射

任何反射操作的第一步都是获取一个 Class 对象，表示要处理的类型。有了这个对象，就能访问表示字段、方法或构造方法的对象，并将其应用于未知类型的实例。

获取未知类型的实例，最简单的方式是使用没有参数的构造方法，这个构造方法可以直接在 Class 对象上调用：

```Java
Class<?> clz = getSomeClassObject();
Object rcvr = clz.newInstance();
```

如果构造方法有参数，必须找到具体需要使用的构造方法，并使用 Constructor 对象表示。
Method 对象是反射 API 提供的对象中最常使用的。Constructor 和 Field 对象在很多方面都和 Method 对象类似。

下面这个示例在 String 对象上调用 hashCode() 方法：

```Java
    public static void invokeHashCode() {
        Object rcvr = "a";
        try {
            Class<?>[] argTypes = new Class[]{};
            Object[] args = null;

            Method method = rcvr.getClass().getMethod("hashCode", argTypes);
            Object ret = method.invoke(rcvr, args);
            System.out.println(ret);

        } catch (IllegalArgumentException | NoSuchMethodException | SecurityException
            | IllegalAccessException | InvocationTargetException e) {
            e.printStackTrace();
        }
    }
```

为了获取想使用的 Method 对象，我们在类对象上调用 getMethod() 方法，得到的是一个 Method 对象的引用，指向这个类中对应的公开方法。

下面这个例子是 通过反射构造一个 String 对象，在上面调用 hashCode() 方法：

```Java
    public static void invokeHashCode1() {
        Class<?> clz = String.class;
        try {
            Class<?>[] argTypes = new Class[]{};
            Object[] args = null;

            Constructor<?> c = clz.getConstructor(String.class);
            Object rcvr = c.newInstance("b");

            Method method = rcvr.getClass().getMethod("hashCode", argTypes);
            Object ret = method.invoke(rcvr, args);
            System.out.println(ret);

        } catch (IllegalArgumentException | NoSuchMethodException | SecurityException
            | IllegalAccessException | InvocationTargetException | InstantiationException e) {
            e.printStackTrace();
        }
    }
```

处理非公开方法的例子：

```Java
    public static void invokeSameSeed() {
        Class<?> clz = RandomTest.class;
        try {
            Constructor<?> c = clz.getConstructor();
            Object rcvr = c.newInstance();

            Method method = rcvr.getClass().getDeclaredMethod("sameSeed");
            method.setAccessible(true);
            method.invoke(rcvr);
        } catch (IllegalArgumentException | NoSuchMethodException | SecurityException
            | IllegalAccessException | InvocationTargetException | InstantiationException e) {
            e.printStackTrace();
        }
    }
```

静态方法不构造实例处理非公开方法的例子：

```Java
    public static void invokeSameSeed1() {
        try {
            Method method = RandomTest.class.getDeclaredMethod("sameSeed");
            method.setAccessible(true);
            method.invoke(null);
        } catch (IllegalArgumentException | NoSuchMethodException | SecurityException
            | IllegalAccessException | InvocationTargetException e) {
            e.printStackTrace();
        }
    }
```

### 反射的问题

Java 的反射 API 往往是处理动态加载代码的唯一方式，不过 API 中有些让人头疼的地方，
处理起来稍微有点困难：

* 大量使用 Object[] 表示调用参数和其他实例；
* 大量使用 Class[] 表示类型；
* 同名方法可以重载，所以需要维护一个类型组成的数组，区分不同的方法；
* 不能很好地表示基本类型——需要手动打包和拆包。

### 何时使用反射

多数 Java 框架都会适度使用反射。如果编写的架构足够灵活，在运行时之前都不知道要处理什么代码，那么通常会使用反射。
反射在测试中也有广泛应用，例如，JUnit 和 TestNG 库都用到了反射，而且创建模拟对象也要使用反射。
如果你用过任何一个 Java 框架，即便没有意识到，也几乎可以确定，你使用的是具有反射功能的代码，比如 spring framework。
