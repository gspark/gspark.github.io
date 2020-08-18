---
title: 使用Java8的Optional的思考
date: 2020-08-17 16:02:38
tags: Java
---

Optional 是 Java 8 引入的一个工具类，也是 Java 8 的新特性之一。在 Stream API 中很多地方也都使用到了 Optional。
空指针异常（NullPointerExceptions）是 Java 最常见的异常之一。程序员不得不在代码中写很多 null 的检查逻辑，让代码看起来非常臃肿；由于其属于运行时异常，非常难以预判的。
为了预防空指针异常，Google 的 Guava 项目率先引入 Optional 类，通过使用检查空值的方式来防止代码污染，受到 Guava 项目的启发，Java 8 中引入了 Optional 类。那在使用 Optional 上有那些值得思考和注意的地方呢。

## isPresent() 和 get() 的思考

虽然官方文档说明中对 Optional 的描述是：`If a value is present, isPresent() will return true and get() will return the value`。我们就调用 isPresent() 和 get() 来避免 NullPointException 好了，但如果只是简单的认为它可以解决 NPE 的问题, 于是代码就会是这样：

```Java
Optional<Student> student = ......
if (student.isPresent()) {
    return student.get().getName();
} else {
    return "";
}
```

那么这种写法这与我们之前写成的：

```Java

Student student = .....
if (student != null) {
    return student.getName();
} else {
    return "";
}
```

本质上是没有区别的。

虽然说使用 ifPresent(Consumer<? super T> consumer) 来替代 isPresent() 要好一些，但是 Consumer 的 accept 函数的返回值是 void 类型，接受单个输入参数且不返回结果的操作，有使用上的限制。

所以，如果我们在使用 Optional 时，如果有需要调用 isPresent() 和 get() 的地方，那就该重新审视一下，是否真的有必要使用 Optional。

## 不要将 Optional 作为函数参数

把 Optional 类型用作函数参数在 IntelliJ IDEA 中是强力不推荐的。这该怎么理解呢？Optional 对象是一个容器对象，它包含的对象是否是空，是不确定的。
函数作为被调用者，它根据传入的参数进行逻辑运算，那么传给它的参数应该是明确的。

参数不为 Optional 的例子：

```Java
public void func1() {
    func2(student);
}

public int func2(Student student) {
    if (student == null) {
        return 0;
    }
    student.setId(getId());
    return insertStudent(name);
}
```

参数为 Optional 的例子：

```Java
public void func1() {
    func2(Optional.ofNullable(student));
}

public int func2(Optional<Student> studentOpt) {
    Student student = studentOpt.orElse(new Student());
    student.setId(getId());
    return insertStudent(student);
}
```

如上两个例子，如果 Optional 为参数的话，按照后一个例子的写法，func2 的逻辑就改变了。
如果要逻辑一致的话，就又会使调用到 isPresent() 和 get() 方法，这样就不如不使用 Optional 更为直接。

## 不要将 Optional 作为字段类型

不要将 Optional 作为字段类型有两个原因：

1. Optional 包含的对象是不确定的
   不确定的数据作为字段值没有什么意义，应该审视是否有更好的设计。
2. Optional 不能支持序列化
   Optional 作为字段类型,如果对象需要被序列化，将会出现异常`Exception in thread "main" java.io.NotSerializableException`。

## Optional 使用举例

除了上述几个场景外，在需要处理 null 的地方，采用 Optional 还是比较好的选择。Optional 虽不能完全杜绝 NPE，但是它能相对优雅的预防 NPE。
比如我们可以这样做：

```Java
Optional<Student> studentOpt = Optional.ofNullable(student);
String name = studentOpt.orElse("");
```

Optional.ofNullable(obj)：以一种宽容的方式来构造一个 Optional 实例。传 null 进到就得到 Optional.empty(), 非 null 就调用 Optional.of(obj)。**Optional.of(obj) 是可能抛出 NPE的，如果参数 obj 为 null 的话。**
Optional.orElse()：存在即返回, 无则提供默认值。

这样看起来比之前的写法要简单很多，改写成一行，更简洁：

```Java
String name = Optional.ofNullable(student).orElse("");
```

比如我们还可以这样，将 Steam 与 Optional 结合起来使用：

```Java
public List<User> getUsers(Collection<Integer> studentIds) {
    return studentIds.stream()
        //此处 getStudentById 返回的是 Optional<Student>
        .map(this::getStudentById)     // 获得 Stream<Optional<Student>>
        .filter(Optional::isPresent)   // 去掉不包含值的 Optional
        .map(Optional::get)
        .collect(Collectors.toList());
}
```

Java 8 的 Optional 除了上述的一些方法，还有一些其它的，像 flatMap 和 orElseThrow 等，可以详细了解一下，找到合适的使用场景。
