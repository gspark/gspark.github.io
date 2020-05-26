---
title: Java单例模式
date: 2020-05-14 15:51:35
tags:
---
软件设计模式（Design pattern），又称设计模式，是一套被反复使用、多数人知晓的、经过分类编目的、代码设计经验的总结。
单例模式（Singleton Pattern）的定义是：保证一个类仅有一个实例，并提供一个访问它的全局访问点。单例模式是一种常用的模式，有一些对象我们往往
只需要一个，比如线程池、全局缓存。单例模式一般被认为是最简单、最易理解的设计模式，也因为它的简洁易懂，是项目中最常用、最易被识别出来的模式。但
单例模式要用好、用对并不是一件简单的事。

## 单例模式的问题

* 单例模式可以有多种实现方法，需要根据情况作出正确的选择
* 单例模式极易被滥用
  如果某个工程中出现了太多单例，就应该重新审视一下设计。
* 单例模式的争议
  * 单例既负责实例化类并提供全局访问，又实现了特定的业务逻辑，一定程度上违背了“单一职责原则”，是反模式的。
  * 单例模式将全局状态（global state）引入了应用，全局状态会引入状态不确定性（state indeterminism），导致微妙的副作用，很容易就会破坏了
    单元测试的有效性。
  * 单例导致了类之间的强耦合，扩展性差，违反了面向对象编程的理念。
    单例封装了自己实例的创建，不适用于继承和多态，同时创建时一般也不传入参数等，难以用一个模拟对象来进行测试。

## Java单例模式的实现

### 懒加载，线程不安全

```Java
public class Singleton {
    private static Singleton instance;
    private Singleton (){}

    public static Singleton getInstance() {
    if (instance == null) {
        instance = new Singleton();
    }  
    return instance;
    }
}
```

### 懒加载，线程安全

```Java
public class Singleton {
    private static Singleton instance;
    private Singleton (){}
    public static synchronized Singleton getInstance() {
        if (instance == null) {
            instance = new Singleton();
        }
        return instance;
    }
}
```

这种写法能够在多线程中很好的工作，而且看起来它也具备很好的lazy loading，但由于加上了同步机制导致效率降低。

### 静态常量

```Java
public class Singleton {
    private final static Singleton instance = new Singleton();
    private Singleton(){}
    public static Singleton getInstance(){
        return instance;
    }
}
```

这种方式基于 classloder 机制，在类加载的时候就完成实例化，Java类加载器初始化静态资源过是线程安全的，避免了线程同步问题。但在类装载的时候就
完成实例化，如果从始至终从未使用过这个实例，则会造成内存的浪费。

### 静态内部类

```Java
public class Singleton {
    private static class SingletonHolder {
        private static final Singleton instance = new Singleton();
    }
    private Singleton (){}
    public static final Singleton getInstance() {
        return SingletonHolder.instance;
    }
}
```

同样利用了 classloder 的机制来保证初始化 instance 时只有一个线程，它和“静态常量”方式不同：“静态常量”方式是只要 Singleton 类被装载了，那么
instance 就会被实例化（没有达到 lazy loading 效果，可能造成资源浪费），而“静态内部类”方式是 Singleton 类被装载了，instance 不一定被初始化。
因为 SingletonHolder 类没有被主动使用，只有显示通过调用 getInstance 方法时，才会显示装载 SingletonHolder 类，从而实例化 instance。

### 双重校验锁

例子：

```Java
public class Singleton {
    private static Singleton instance;
    private Singleton (){}
    public static Singleton getInstance() {
        if (instance == null) {
            synchronized (Singleton.class) {
                if (instance == null) {
                    instance = new Singleton();
                }
            }
        }
        return instance;
    }
}  
```

第一次校验：由于单例模式只需要创建一次实例，如果后面再次调用 getInstance 方法时，则直接返回之前创建的实例，因此大部分时间不需要执行同步方法里面
的代码，大大提高了性能。如果不加第一次校验的话，那跟上面的“静态常量”方式没什么区别，每次都要去竞争锁。

第二次校验：如果没有第二次校验，假设线程t1执行了第一次校验后，判断为null，这时t2也获取了CPU执行权，也执行了第一次校验，判断也为null。
接下来t2获得锁，创建实例。这时t1又获得CPU执行权，由于之前已经进行了第一次校验，结果为null（不会再次判断），获得锁后，直接创建实例。结果就会导致
创建多个实例。所以需要在同步代码里面进行第二次校验，如果实例为空，则进行创建。

但这个例子是错误的，问题的原因在于JVM指令重排优化。
`instance = new Singleton();` 这行，当某个线程执行这行语句时，构造函数的调用似乎应该在 instance 得到赋值之前发生，但是在java虚拟机内部，
却不是这样的，完全有可能先new出来一个空的未调用过构造函数的 instance 对象，然后再将其赋值给 instance 引用，然后再调用构造函数，
对 instance 对象当中的元素进行初始化。若紧接着另外一个线程来调用 getInstance，取到的就是状态不正确的对象，程序可能就会出错。

### 枚举

```Java
public enum Singleton {  
    INSTANCE;
    public void something() {
    }
}
```

枚举的方式实现单例，可以保证线程安全。

### 破除单例模式的方法

#### 克隆

如果类继承了 Cloneable 接口，并且实现了 clone 方法，尽管这个类的构造函数是私有的，还是可以创建一个对象。

```Java
public class Singleton implements Cloneable {

    private static Singleton instance;
    private Singleton (){}

    private String id = "999";

    public static synchronized Singleton getInstance() {
        if (instance == null) {
            instance = new Singleton();
        }
        return instance;
    }

    @Override
    public Object clone() throws CloneNotSupportedException {
        return super.clone();
    }
}

public static void singleton(){
    com.shrill.singleton.Singleton s = com.shrill.singleton.Singleton.getInstance();
    com.shrill.singleton.Singleton s1 = null;
    try {
        s1 = (com.shrill.singleton.Singleton) s.clone();
        System.out.println("s  hashCode:" + s.hashCode());
        System.out.println("s1 hashCode:" + s1.hashCode());
    } catch (CloneNotSupportedException e) {
        e.printStackTrace();
    }
}
// 输出
s  hashCode:1618212626
s1 hashCode:1129670968
```

hash 值不一样，所以克隆成功了，生成了一个新对象。单例模式被成功破坏！

#### 序列化

假设你的单例模式，实现了 Serializable 接口，那模式可能会被破坏。如下例：

```Java
public class SerSingleton implements Serializable {


    private static SerSingleton instance;

    private SerSingleton() {
    }

    private String id = "999";

    public static synchronized SerSingleton getInstance() {
        if (instance == null) {
            instance = new SerSingleton();
        }
        return instance;
    }
}

public static void serSingleton() {
    SerSingleton s1 = null;
    SerSingleton s = SerSingleton.getInstance();

    try (ObjectOutputStream oos = new ObjectOutputStream(new FileOutputStream("z:\\a.bin"))) {
        oos.writeObject(s);
        oos.flush();
    } catch (IOException e) {
        e.printStackTrace();
    }

    try (ObjectInputStream ois = new ObjectInputStream(new FileInputStream("z:\\a.bin"))) {
        s1 = (SerSingleton) ois.readObject();
        if (null != s1) {
            System.out.println("s  hashCode:" + s.hashCode());
            System.out.println("s1 hashCode:" + s1.hashCode());
        }
    } catch (IOException | ClassNotFoundException e) {
        e.printStackTrace();
    }
}
// 输出
s  hashCode:1729199940
s1 hashCode:127618319
```

解决办法，实现 readResolve 方法，返回 instance。

```Java
private Object readResolve() {
    return instance;
}
```

#### 反射

通过反射可以执行对象的非公开方法，那么就可以执行对象的私有构造方法，从而构造出一个新的对象，单例模式又被破坏了。解决方法：

```Java
private SerSingleton() {
    if (null != instance) {
        throw new RuntimeException();
    }
}
```

### 再说枚举单例模式

前面提到枚举的方式实现单例，可以保证线程安全，它是怎样做到呢？
定义枚举时使用enum和class一样，是Java中的一个关键字。就像class对应用一个Class类一样，enum也对应有一个Enum类。通过将定义好的枚举反编译就能
发现，枚举在经过javac的编译之后，会被转换成形如public final class T extends Enum的定义。而且，枚举中的各个枚举项是通过static来定义的。
如：

```Java
public enum SingletonEnum implements Serializable, Cloneable {
    INSTANCE;

    private String id = "999";

    SingletonEnum() {
        System.out.println("SingletonEnum create");
    }

    public int getHashCode() {
        return this.hashCode();
    }
}
```

反编译结果：

```Java
public final class com.shrill.singleton.SingletonEnum extends java.lang.Enum<com.shrill.singleton.SingletonEnum> implements java.io.Serializable, java.lang.Cloneable {
  public static final com.shrill.singleton.SingletonEnum INSTANCE;
  public static com.shrill.singleton.SingletonEnum[] values();
  public static com.shrill.singleton.SingletonEnum valueOf(java.lang.String);
  public int getHashCode();
  static {};
}
```

可以看到 INSTANCE 变量加上静态属性，而Java类加载器初始化静态资源过是线程安全的，所以，创建一个enum类型是线程安全的。

由于枚举没有 clone 方法，即是实现了 Cloneable 也没有 clone 方法可被调用，所以通过 enum 实现的单例模式不会被 clone 破坏。

对于序列化，枚举的特殊之处又在哪里？普通的Java类的反序列化过程中，会通过反射调用类的默认构造函数来初始化对象。即使单例中构造函数是私有的，也会被
反射给破坏掉。由于反序列化后的对象是重新 new 出来的，所以这就破坏了单例。Java 序列化枚举对象仅仅是将枚举对象的name属性输出到结果中，反序列化的
时候则是通过java.lang.Enum的valueOf方法来根据名字查找枚举对象。同时，编译器是不允许任何对枚举这种序列化机制的定制，因此禁用了
writeObject、readObject等方法。所以通过 enum 实现的单例模式不会被 序列化 破坏。`valueOf`方法：

```Java
public static <T extends Enum<T>> T valueOf(Class<T> enumType,
                                                String name) {
    T result = enumType.enumConstantDirectory().get(name);
    if (result != null)
        return result;
    if (name == null)
        throw new NullPointerException("Name is null");
    throw new IllegalArgumentException(
        "No enum constant " + enumType.getCanonicalName() + "." + name);
}
```

首先调用 enumType 这个 Class 对象的 enumConstantDirectory 方法返回的 map 中获取名字为name的枚举对象，如果不存在就会抛出异常。
跟进`enumConstantDirectory`方法,发现到最后会以反射的方式调用 enumType 这个类型的 values() 静态方法，也就是上面我们看到的编译器为我们创建的那个方法，然后用返回结果填充enumType这个Class对象中的enumConstantDirectory属性。

例子：

```Java
public static void singletonEnum() {
    SingletonEnum s = SingletonEnum.INSTANCE;

    try (ObjectOutputStream oos = new ObjectOutputStream(new FileOutputStream("z:\\b.bin"))) {
        oos.writeObject(s);
        oos.flush();
    } catch (IOException e) {
        e.printStackTrace();
    }
    SingletonEnum s1 = null;
    try (ObjectInputStream ois = new ObjectInputStream(new FileInputStream("z:\\b.bin"))) {
        s1 = (SingletonEnum) ois.readObject();
        if (null != s1) {
            System.out.println("s  hashCode:" + s.hashCode());
            System.out.println("s1 hashCode:" + s1.hashCode());
        }
    } catch (IOException | ClassNotFoundException e) {
        e.printStackTrace();
    }
}
//输出:

SingletonEnum create
s  hashCode:1020391880
s1 hashCode:1020391880
s equals s1 true
```

说明序列化后是同一个对象。

java 语言规范禁止对枚举类型的反射实例化。所以反射也对枚举实现的单例不能起破坏作用。例子：

```Java
public static void singletonEnum1() {
    SingletonEnum s = SingletonEnum.INSTANCE;
    System.out.println("s  hashCode:" + s.getHashCode());

    Class<?> clz = SingletonEnum.class;
    try {
        Constructor<?> c = clz.getConstructor();
        Object rcvr = c.newInstance();

        Method method = rcvr.getClass().getMethod("getHashCode");
        method.invoke(rcvr);
    } catch (IllegalArgumentException | NoSuchMethodException | SecurityException
        | IllegalAccessException | InvocationTargetException | InstantiationException e) {
        e.printStackTrace();
    }
}
输出：
SingletonEnum create
s  hashCode:1618212626
java.lang.NoSuchMethodException: com.shrill.singleton.SingletonEnum.<init>()
    at java.lang.Class.getConstructor0(Class.java:3082)
    at java.lang.Class.getConstructor(Class.java:1825)
    at com.shrill.SingletonApp.singletonEnum(SingletonApp.java:62)
```

反射会抛出异常。
