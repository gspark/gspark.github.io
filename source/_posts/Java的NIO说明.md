---
title: Java的NIO说明
date: 2018-03-12 10:53:07
tags: [Java, NIO]
---
# Java的NIO说明

Java NIO，是Java SE 1.4版以后，针对网络传输效能优化的新功能。在Java 7时再推出NIO 2，针对档案存取的效能优化。

有些资料将 NIO 称之为 Non-block I/O，即非阻塞I/O，这个说法不是很正确。NIO 应该称为 New I/O，参考[JSR 51: New I/O APIs for the JavaTM Platform](https://www.jcp.org/en/jsr/detail?id=51)。因为NIO支持阻塞和非阻塞这两种模式，所以将NIO称之为 Non-block I/O 就不准确了。

NIO.2是“APIs for filesystem access, scalable asynchronous I/O operations, socket-channel binding and configuration, and multicast datagrams. ”，上述描述抄自[JSR 203](https://www.jcp.org/en/jsr/detail?id=203)，简单来说就是一些 API 用于文件系统访问、可伸缩的异步 i/o 操作、套接字通道绑定和配置以及多播数据报。

由于NIO.2具有异步能力，所以NIO.2又被称为AIO(Asynchronous I/O)。

## 名词解释

1. 阻塞和非阻塞  
   阻塞调用在调用结果返回之前，当前线程会被挂起。调用线程只有在得到结果之后才会返回。非阻塞调用在不能立刻得到结果之前，该调用不会阻塞当前线程。  
   阻塞和非阻塞关注的是程序在等待调用结果（消息，返回值）时的**状态**。

2. 同步和异步  
   同步，就是在发出一个“调用”时，在没有得到结果之前，该“调用”就不返回。但是一旦**调用返回**，就得到返回值了。换句话说，就是由“调用者”主动等待结果。  
   异步则是相反，“调用”在发出之后，这个调用就直接返回了，没有返回结果。换句话说，当一个异步过程调用发出后，调用者不会立刻得到结果。而是在“调用”发出后，“被调用者”通过状态、通知来通知调用者，或回调处理这个调用。  
   同步和异步关注的是**获取结果的方式**。[[1]](#reference)

   从上面的解释来看，虽然阻塞/非阻塞和同步/异步是两组关注点不同的概念，还是存在一些疑惑：
   + 阻塞和同步的区别是什么？  
     阻塞调用会一直block住对应的进程（线程）直到操作完成，数据从kernel中拷贝到用户内存后，用户进程（线程）解除blocking。同步可以是阻塞的也可以是非阻塞的。
   + 非阻塞和异步的区别是什么？  
     非阻赛是在kernel还在准备数据的情况下会立刻返回，用户进程（线程）可通过轮询kernel等方式，直到数据准备好再拷贝数据到用户内存来获取数据，这种方式就是同步非阻塞。异步就是用户进程将整个操作交给了他人（kernel）完成，然后他人做完后发信号通知。在此期间，用户进程不需要去检查IO操作的状态，也不需要主动的去拷贝数据，kernel已经将数据拷贝至用户内存。

## NIO与AIO

通过上面的解释我们知道了NIA与AIO的区别，由于AIO具备异步的特性，它不需要采用轮询的方式来获取数据，只需等待通知就可以获取数据，摒除了空等，相对NIO来说性能有所提高。

## Java NIO direct buffer的优势

以下是官方文档给出的说明：

Given a direct byte buffer, the Java virtual machine will make a best effort to perform native I/O operations directly upon it. That is, it will attempt to avoid copying the buffer's content to (or from) an intermediate buffer before (or after) each invocation of one of the underlying operating system's native I/O operations.

大致意思是：给定一个直接字节缓冲区，Java虚拟机将尽最大努力直接对它执行本地 I/O 操作。也就是说，它将尝试避免在每次调用某个底层操作系统的本地 I/O操作之前（或之后）将缓冲区内容复制到中间缓冲区（或从中间缓冲区复制到缓冲区）。

优势很明显，减少一次拷贝过程。

NIO 操作的时候，那么是不是有这么一个中间缓冲区呢？

Java NIO 在读写到相应的 Channel 的时候，会先将 Java Heap 的 buffer 内容拷贝至直接内存—— Direct Memory。这样的话，采用 DirectByteBuffer 的性能肯定强于使用 HeapByteBuffer，它省去了临时buffer的拷贝开销，这也是为什么各个NIO框架大多使用DirectByteBuffer的原因。

绝大部分Channel类都是通过sun.nio.ch.IOUtil，这个工具类和外界进行通讯的，如FileChannel/SocketChannel等等，查看sun.nio.ch.IOUtil#read和sun.nio.ch.IOUtil#write代码可以证明这点。

``` Java
static int read(FileDescriptor var0, ByteBuffer var1, long var2, NativeDispatcher var4) throws IOException {
    if (var1.isReadOnly()) {
        throw new IllegalArgumentException("Read-only buffer");
    } else if (var1 instanceof DirectBuffer) {
        return readIntoNativeBuffer(var0, var1, var2, var4);
    } else {
        ByteBuffer var5 = Util.getTemporaryDirectBuffer(var1.remaining());

        int var7;
        try {
            int var6 = readIntoNativeBuffer(var0, var5, var2, var4);
            var5.flip();
            if (var6 > 0) {
                var1.put(var5);
            }

            var7 = var6;
        } finally {
            Util.offerFirstTemporaryDirectBuffer(var5);
        }

        return var7;
    }
}

static int write(FileDescriptor var0, ByteBuffer var1, long var2, NativeDispatcher var4) throws IOException {
    if (var1 instanceof DirectBuffer) {
        return writeFromNativeBuffer(var0, var1, var2, var4);
    } else {
        int var5 = var1.position();
        int var6 = var1.limit();

        assert var5 <= var6;

        int var7 = var5 <= var6 ? var6 - var5 : 0;
        ByteBuffer var8 = Util.getTemporaryDirectBuffer(var7);

        int var10;
        try {
            var8.put(var1);
            var8.flip();
            var1.position(var5);
            int var9 = writeFromNativeBuffer(var0, var8, var2, var4);
            if (var9 > 0) {
                var1.position(var5 + var9);
            }

            var10 = var9;
        } finally {
            Util.offerFirstTemporaryDirectBuffer(var8);
        }

        return var10;
    }
}
```

从上面的代码可以看出，如果 var1 是 Directbuffer 就直接拷贝（或写入），否则创建一个临时 Directbuffer，将 var1 写入这个临时 Directbuffer，然后再拷贝（或写入）。

Java为什么在执行网络IO或者文件IO时，一定要通过堆外内存呢？

HeapByteBuffer 内存是分配在堆上的，直接由 Java 虚拟机负责垃圾收集，DirectByteBuffer 是通过 JNI 在 Java 虚拟机外的内存中分配了一块内存（所以即使在运行时通过 -Xmx 指定了 Java 虚拟机的最大堆内存，还是可能实例化超出该大小的 Direct ByteBuffer），DirectByteBuffer 是用户空间的，它的创建是使用了 malloc 申请的内存，该内存块并不直接由 Java 虚拟机负责垃圾收集，但是在 Direct ByteBuffer 包装类被回收时，会通过 Java Reference 机制来释放该内存块。

当把一个地址通过JNI传递给底层的C库的时候，有一个基本的要求，就是这个地址上的内容不能失效。然而，在GC管理下的对象是会在Java堆中移动的。也就是说，有可能把一个地址传给底层的write，但是这段内存却因为GC整理内存而失效了。所以必须要把待发送的数据放到一个GC管不着的地方。这就是调用native方法之前，数据一定要在堆外内存的原因。DirectBuffer 没有省内存拷贝，但是使用HeapBuffer却需要多一次拷贝，所以相对来说Directbuffer要快。

此外，Directbuffer 的 GC 压力更小。虽然 GC 仍然管理着 DirectBuffer 的回收，但它是使用 PhantomReference 来达到的，在平常的 Young GC 或者 mark and compact 的时候却不会在内存里搬动。如果IO的数量比较大，比如在网络发送很大的文件，那么 GC 的压力下降就会很明显。[[2]](#reference)

## 后记

I/O模型中只有同步阻塞、同步非阻塞和异步，没有异步非阻塞。

所有的系统I/O都分为两个阶段：等待就绪和操作。举例来说，读函数，分为等待系统可读和真正的读；同理，写函数分为等待网卡可以写和真正的写。

下图是几种常见I/O模型的对比：
![IO module](nio2.jpg)

下图是阻塞/非阻塞和同步/异步的小结：
![同步/异步](IO.jpg)

<div id="reference"></div>

## 参考

1. [怎样理解阻塞非阻塞与同步异步的区别？](https://www.zhihu.com/question/19732473)

2. [Java NIO direct buffer的优势在哪儿？](https://www.zhihu.com/question/60892134/answer/182225677)


