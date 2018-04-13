---
title: 回顾Java类加载器(续)
date: 2018-04-12 15:41:21
tags: Java
---
# 回顾 Java 类加载器(续)

类加载器负责读取 Java 字节代码，并转换成 java.lang.Class 类的一个实例。Class 对象是在加载类时由 Java 虚拟机以及通过调用类加载器中的 defineClass 方法自动构造的，因此不能显式地声明一个Class对象。

## 显式加载类

在代码中显式加载某个类，有三种方法：

1. this.getClass().getClassLoader().loadClass()
2. Class.forName()
3. CustomClassLoader.findClass()

loadClass会调用findClass。

## loadClass()

ClassLoader.loadClass()的加载步骤为：

1. 调用 findLoadedClass(String) 来检查是否已经加载类。
2. 在父类加载器上调用 loadClass 方法。如果父类加载器为 null，则使用虚拟机的内置类加载器。
3. 调用 findClass(String) 方法查找类。

```Java
protected Class<?> loadClass(String name, boolean resolve)
        throws ClassNotFoundException
{
    synchronized (getClassLoadingLock(name)) {
        // First, check if the class has already been loaded
        Class<?> c = findLoadedClass(name);
        if (c == null) {
            long t0 = System.nanoTime();
            try {
                if (parent != null) {
                    c = parent.loadClass(name, false);
                } else {
                    c = findBootstrapClassOrNull(name);
                }
            } catch (ClassNotFoundException e) {
                // ClassNotFoundException thrown if class not found
                // from the non-null parent class loader
            }

            if (c == null) {
                // If still not found, then invoke findClass in order
                // to find the class.
                long t1 = System.nanoTime();
                c = findClass(name);

                // this is the defining class loader; record the stats
                sun.misc.PerfCounter.getParentDelegationTime().addTime(t1 - t0);
                sun.misc.PerfCounter.getFindClassTime().addElapsedTimeFrom(t1);
                sun.misc.PerfCounter.getFindClasses().increment();
            }
        }
        if (resolve) {
            resolveClass(c);
        }
        return c;
    }
}
```

### ClassLoader.findClass()

ClassLoader.loadClass()的最后一步是调用findClass()，这个方法在ClassLoader中并未实现，由其子类负责实现。findClass()的功能是找到class文件并把字节码加载到内存中。自定义的ClassLoader一般会覆盖这个方法，以便使用不同的加载路径。
URLClassLoader 的findClass 代码：

```Java
protected Class<?> findClass(final String name)
        throws ClassNotFoundException
{
    final Class<?> result;
    try {
        result = AccessController.doPrivileged(
            new PrivilegedExceptionAction<Class<?>>() {
                public Class<?> run() throws ClassNotFoundException {
                    String path = name.replace('.', '/').concat(".class");
                    Resource res = ucp.getResource(path, false);
                    if (res != null) {
                        try {
                            return defineClass(name, res);
                        } catch (IOException e) {
                            throw new ClassNotFoundException(name, e);
                        }
                    } else {
                        return null;
                    }
                }
            }, acc);
    } catch (java.security.PrivilegedActionException pae) {
        throw (ClassNotFoundException) pae.getException();
    }
    if (result == null) {
        throw new ClassNotFoundException(name);
    }
    return result;
}
```

1. ucp 是 URLClassPath 对象，帮助获取 class 文件字节流，URLClassPath 会用 FileLoader 或者 JarLoader 去加载字节码。
2. defineClass()，创建类对象，将类字节码解析成 JVM 能够识别的 Class 对象。

```Java
private Class<?> defineClass(String name, Resource res) throws IOException {
    long t0 = System.nanoTime();
    int i = name.lastIndexOf('.');
    URL url = res.getCodeSourceURL();
    if (i != -1) {
        String pkgname = name.substring(0, i);
        // Check if package already loaded.
        Manifest man = res.getManifest();
        definePackageInternal(pkgname, man, url);
    }
    // Now read the class bytes and define the class
    java.nio.ByteBuffer bb = res.getByteBuffer();
    if (bb != null) {
        // Use (direct) ByteBuffer:
        CodeSigner[] signers = res.getCodeSigners();
        CodeSource cs = new CodeSource(url, signers);
        sun.misc.PerfCounter.getReadClassBytesTime().addElapsedTimeFrom(t0);
        return defineClass(name, bb, cs);
    } else {
        byte[] b = res.getBytes();
        // must read certificates AFTER reading bytes.
        CodeSigner[] signers = res.getCodeSigners();
        CodeSource cs = new CodeSource(url, signers);
        sun.misc.PerfCounter.getReadClassBytesTime().addElapsedTimeFrom(t0);
        return defineClass(name, b, 0, b.length, cs);
    }
}
```

## Class.forName

Class的装载分了三个阶段，loading，linking和initializing，分别定义在The Java Language Specification的12.2，12.3和12.4。

Class.forName(className)实际上是调用Class.forName(className, true, ClassLoader.getClassLoader(caller), caller)。注意第二个参数，是指Class被loading后是不是必须被初始化。

```Java
public static Class<?> forName(String className)
            throws ClassNotFoundException {
    Class<?> caller = Reflection.getCallerClass();
    return forName0(className, true, ClassLoader.getClassLoader(caller), caller);
}
```

ClassLoader.loadClass(className)实际上调用的是ClassLoader.loadClass(name, false)，第二个参数指出Class是否被link。

```Java
public Class<?> loadClass(String name) throws ClassNotFoundException {
    return loadClass(name, false);
}
```

区别就出来了。Class.forName(className)装载的class已经被初始化，会执行类中的 static 块和 static 方法，而ClassLoader.loadClass(className)装载的class还没有被link。
一般情况下，这两个方法效果一样，都能装载Class。但如果程序依赖于Class是否被初始化，就必须用Class.forName(name)了。
