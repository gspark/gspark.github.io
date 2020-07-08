---
title: Java8流使用简介
date: 2020-06-12 11:41:42
tags:
---

Stream API支持的许多操作。这些操作能让你快速完成复杂的数据查询，如筛选、切片、映射、查找、匹配和归约。

## 筛选和切片

Streams 接口支持 filter 方法。该操作会接受一个谓词（一个返回 boolean 的函数）作为参数，并返回一个包括所有符合谓词的元素的流。
流还支持一个叫作 distinct 的方法，它会返回一个元素各异（根据流所生成元素的 hashCode 和 equals 方法实现）的流。
看下面一个例子，筛选出列表中所有的偶数，并确保没有重复：

```Java
List<Integer> numbers = Arrays.asList(1, 2, 1, 3, 3, 2, 4, 6);
numbers.stream()
    .filter(i -> i % 2 == 0)
    .distinct()
    .forEach(System.out::println);
```

输出：

```sh
2
4
6
```

## 跳过元素

流还支持skip(n)方法，返回一个扔掉了前n个元素的流。如果流中元素不足n个，则返回一个空流。请注意，limit(n)和skip(n)是互补的。
如下例，跳过超过90分的头1个学生，并剩下的学生中的头3个的姓名：

```Java
List<String> goodStudentNames = students.stream()
    .filter(s -> {
        System.out.println("filter-> " + s.getName());
        return s.getScore() > GOOD;
    })
    .skip(1)
    .map(s -> {
        System.out.println("map-> " + s.getName());
        return s.getName();
    })
    .limit(3)
    .collect(toList());

System.out.println(goodStudentNames);
```

## 映射

Stream API 通过 map 和 flatMap 方法从某些对象中选择信息。
map方法，它会接受一个函数作为参数。这个函数会被应用到每个元素上，并将其映射成一个新的元素（使用映射一词，是因为它和转换类似，但其中的细微差别在于
它是“创建一个新版本”而不是去“修改”）。

给定一个单词列表，返回另一个列表，显示每个单词中有几个字母。可以像下例，给 map 传递一个方法引用 String::length 来解决这个问题。

```Java
List<String> words = Arrays.asList("Java 8", "Lambdas", "In", "Action");
List<Integer> wordLengths = words.stream()
    .map(String::length)
    .collect(toList());
System.out.println(wordLengths);
```

输出：

```sh
[6, 7, 2, 6]
```

## 扁平化

对于一张单词表，如何返回一张列表，列出里面各不相同的字符呢？例如，给定单词列表["Hello","World"]，你想要返回列表["H","e","l", "o","W","r","d"]。
可以用 flatMap 来解决这个问题。程序如下：

```Java
List<String> words = Arrays.asList("Hello", "World");

List<String> uniqueCharacters =
    words.stream()
        .map(w -> w.split(""))
        .flatMap(Arrays::stream)
        .distinct()
        .collect(Collectors.toList());
System.out.println(uniqueCharacters);
```

Arrays.stream()的方法可以接受一个数组并产生一个流，如下例：

```Java
String[] arrayOfWords = {"Goodbye", "Tom"};
Stream<String> streamOfwords = Arrays.stream(arrayOfWords);
```

map(w -> w.split("")) 得到 `Stream<String[]>`。
flatMap(Arrays::stream) 得到 `Stream<String>`，使用 flatMap 方法的效果是，各个数组并不是分别映射成一个流，而是映射成流的内容。所
有使用map(Arrays::stream)时生成的单个流都被合并起来，即扁平化为一个流。
如果是map
map(Arrays::stream) 得到 `Stream<Stream<String>>`

再看一个问题：给定两个数字列表，如何返回所有的数对呢？例如，给定列表[1, 2, 3]和列表[3, 4]，应该返回
[(1, 3), (1, 4), (2, 3), (2, 4), (3, 3), (3, 4)]。为简单起见，用有两个元素的数组来代表数对。

```Java
List<Integer> numbers1 = Arrays.asList(1, 2, 3);
List<Integer> numbers2 = Arrays.asList(3, 4);

List<int[]> pairs = numbers1.stream()
    .flatMap(
        i -> numbers2.stream().map(j -> new int[]{i, j})
    )
    .collect(toList());
```

当 i = 1 时 i -> numbers2.stream().map(j -> new int[]{i, j}) 得到
Stream<Int[]> (1,3), Stream<Int[]> (1,4) 这一对流。
依次循环，会得到 3 对流，flatMap 对这 3 对流扁平化，新成包含 6 个数组的一个流。

扩展上面的问题，只返回总和能被3整除的数对呢？可利用 filter 来实现:

```Java
List<Integer> numbers1 = Arrays.asList(1, 2, 3);
List<Integer> numbers2 = Arrays.asList(3, 4);

List<int[]> pairs = numbers1.stream()
    .flatMap(
        i -> numbers2.stream()
            .filter(j -> (i + j) % 3 == 0)
            .map(j -> new int[]{i, j})
    )
    .collect(toList());
```

输出：

```sh
[(2,4)(3,3)]
```

## 查找和匹配

Stream API通过allMatch、anyMatch、noneMatch、findFirst和findAny方法，来判断数据集中的某些元素是否匹配一个给定的属性。

## 归约

将流中所有元素反复结合起来，得到一个值，比如一个Integer。这样的查询可以被归类为归约操作（将流归约成一个值）。

### 元素求和

对流中所有的元素求和：

```Java
List<Integer> numbers = Arrays.asList(4, 5, 3, 9);
int sum = numbers.stream().reduce(0, (a, b) -> a + b);
```

reduce接受两个参数：

1. 初始值，这里是0
2. BinaryOperator<T>来将两个元素结合起来产生一个新值，这里我们用的是lambda (a, b) -> a + b。
首先，0作为Lambda（a）的第一个参数，从流中获得4作为第二个参数（b）。0 + 4得到4，它成了新的累积值。
然后再用累积值和流中下一个元素5调用Lambda，产生新的累积值9。接下来，再用累积值和下一个元素3调用Lambda，得到12。
最后，用12和流中最后一个元素9调用Lambda，得到最终结果21。

在Java 8中，Integer类现在有了一个静态的 sum 方法来对两个数求和，用不着反复用Lambda写同一段代码了：

```Java
int sum = numbers.stream().reduce(0, Integer::sum);
```

如果没有初始值，reduce 还有一个重载的变体，它不接受初始值，但是会返回一个Optional对象：

```Java
Optional<Integer> sum = numbers.stream().reduce((a, b) -> (a + b));
```

### 最大值、最小值

我们利用刚刚学到的 reduce 来计算流中最大或最小的元素是否可能，该怎样做呢？
正如前面描述的，reduce接受两个参数：

1. 一个初始值
2. 一个 Lambda 来把两个流元素结合起来并产生一个新值

那么我们需要一个给定两个元素能够返回最大值和最小值的 Lambda 表达式。

```Java
Optional<Integer> min = numbers.stream().reduce((x, y) -> x > y ? y : x);
Optional<Integer> max = numbers.stream().reduce(Integer::max);
System.out.println("min: " + min.orElse(0) + " max: " + max.orElse(0));
```

输出：

```sh
min: 3 max: 9
```

## 构建

### 值创建

使用静态方法 Stream.of，通过显式值创建一个流。它可以接受任意数量的参数。例如，以下代码直接使用 Stream.of 创建了一个字符串流。
然后将字符串转换为大写，再一个个打印出来：

```Java
Stream<String> stream = Stream.of("Java 8 ", "Lambdas ", "In ", "Action");
stream.map(String::toUpperCase).forEach(System.out::println);
```

### 数组创建

使用静态方法Arrays.stream从数组创建一个流。它接受一个数组作为参数。例如，将一个原始类型int的数组转换成一个IntStream，如下所示：

```Java
int[] numbers = {2, 3, 5, 7, 10, 14};
int sum = Arrays.stream(numbers).sum();
```

### 文件生成流

Java中用于处理文件等I/O操作的NIO API 已更新，以便利用Stream API。java.nio.file.Files 中的很多静态方法都会返回一个流。
如下例：

```Java
long uniqueWords = 0;
try(Stream<String> lines =
          Files.lines(Paths.get("data.txt"), Charset.defaultCharset())){
uniqueWords = lines.flatMap(line -> Arrays.stream(line.split(" ")))
                   .distinct()
                   .count();
}  
catch(IOException e){

}
```

使用Files.lines得到一个流，其中的每个元素都是给定文件中的一行。然后对line调用split方法将行拆分成单词。应该注意的是，该如何使用flatMap产生一个扁
平的单词流，而不是给每一行生成一个单词流。最后，把distinct和count方法链接起来，数数流中有多少各不相同的单词。

### 函数生成流

Stream API提供了两个静态方法来从函数生成流：Stream.iterate和Stream.generate。这两个操作可以创建所谓的无限流。
一般来说，应该使用limit(n)来对这种流加以限制。

1. 迭代

```Java
Stream.iterate(0, n -> n + 2)
      .limit(10)
      .forEach(System.out::println);
```

iterate 方法接受一个初始值（在这里是0），还有一个依次应用在每个产生的新值上的Lambda。这里，我们使用`n -> n + 2`，返回的是前一个元
素加上 2。因此，iterate 方法生成了一个所有正偶数的流：流的第一个元素是初始值 0。然后加上 2 来生成新的值 2，再加上 2 来得到新的值 4，以此类推。
这种iterate操作基本上是顺序的，因为结果取决于前一次应用。此操作将生成一个无限流——这个流没有结尾，因为值是按需计算的，可以永远计算下去。
我们说这个流是无界的。使用limit方法来显式限制流的大小。这里只选择了前10个偶数。然后可以调用forEach终端操作来消费流，并分别打印每个元素。

2. 生成

generate 方法也可让你按需生成一个无限流。但 generate 不是依次对每个新生成的值应用函数的。它接受一个 Supplier<T> 类型的 Lambda 提供新的值。
我们先来看一个简单的用法：

```Java
Stream.generate(Math::random)
      .limit(5)
      .forEach(System.out::println);
```

这段代码将生成一个流，其中有五个0到1之间的随机双精度数。
