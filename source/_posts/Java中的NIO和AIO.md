---
title: Java中的NIO和AIO
date: 2018-03-12 10:53:07
tags:
---
# Java中的NIO和AIO

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
   同步和异步关注的是**获取结果的方式**。

   从上面的解释来看，虽然阻塞/非阻塞和同步/异步是两组关注点不同的概念，还是存在一些疑惑：
   + 阻塞和同步的区别是什么？  
     调用blocking IO会一直block住对应的进程（线程）直到操作完成，数据从kernel中拷贝到用户内存后，用户进程（线程）解除blocking，而non-blocking IO在kernel还在准备数据的情况下会立刻返回，用户进程（线程）可通过轮询kernel等方式，直到数据准备好再拷贝数据到用户内存来获取数据。
   + 非阻塞和异步的区别是什么？
