---
title: git:Authentication failed for 又不弹出用户名和密码windows解决方法
date: 2018-09-06 15:41:00
tags: git
---

# fatal: Authentication failed for又不弹出用户名和密码

最近用tortoisegit更新或者提交代码，提示fatal: Authentication failed for，但是又不能够弹出输入账号密码框。

# 解决方法

搞了半天在命令行下：

```bat
git config --system --unset credential.helper
```

然后就终于可以重新填写用户名和密码进行提交了。

但是这样一来，用户名和密码不能保存，每次更新和提交都提示输入密码，很麻烦。继续研究...

# 安装Git-Credential-Manager-for-Windows

执行命令：

```bat
git config --global credential.helper manager
```

这下好了，在Users下生成了.gitconfig 文件，里面的内容如下：

```json
[credential]
	helper = manager
```

# windows下另外一种可能方案

在控制面板的``用户帐户\凭据管理器``里面有个`windows 凭证`，删除出错的账户凭证，可能就可以解决问题了。