---
title: visual studio C++工程.vs文件夹过大
date: 2023-03-14 14:17:23
tags: c++
---

visual studio 的 c++ 工程因为 IntelliSense 会在 .vs 文件夹里面生产磁盘缓存，缓存文件有时候会变得很大，导致 .vs 文件夹非常巨大。解决方法如下：

1. 修改缓存文件位置
   Tools | Options | Text Editor | C/C++ | Advanced 标签页，找到 Browsing Database Fallback，将 的 Always Use Fallback Location 和 Do Not Warn If Fallback Location Used 设为 true。然后设置 Fallback Location 缓存文件的路径。

2. 设置 IntelliSense 的自动预编译标头为禁用
   Tools | Options | Text Editor | C/C++ | Advanced 标签页，找到 IntelliSense，设置 `Disable Automatic Precompiled Header` 为 true。这样会减小 IntelliSense 的操作速度，但可以减小缓存文件的大小。
