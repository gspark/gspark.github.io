---
title: onclick无效的一个原因
date: 2021-06-04 17:45:34
tags:
---

写 html 的时候发现 onclick 的事件不生效，另外再写一个 onclick 事件又能够成功。花了好久查不到原因。代码如下：

```html
<div id="choosefile" onclick="choosefile();">
    <div style="text-align:center">open md file</div>
    <input type="file" id="file0" style="display: none" onchange="selectedFile();">
</div>

<input type="button" id="save0" value="保存" οnclick="alert('hello world')" />

<input type="button" id="md0" value="导出文档" οnclick="exportFile()" />
```

后面两个 button 的click事件不生效。

正常来说，字符 o 对应的 ascii 码值应为 111，但是上面代码中后面两个 button click 事件的“οnclick”的 ο 的 ascii码值为 959 ，看起来与普通的字符 o 是一样的，但是浏览器只能识别 111，导致程序错误。
将 ο 改成 o 问题就解决了。

ascii码值为 959的 ο 是什么呢？是希腊小写字母 omicron。
