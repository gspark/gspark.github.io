---
title: 使用git-svn管理svn代码仓库
date: 2019-07-01 15:05:33
tags: git
---

## 使用git-svn管理svn代码仓库

现在大部分代码仓库是采用git管理，但由于历史原因，有些代码仓库继续由svn管理。git提供了git-svn工具，可使用git管理svn代码。最后的效果相当于把svn仓库当作git的一个remote（远程仓库），而你本地的代码都是通过git来管理，只有push到svn时才会把你本地的commit同步到svn。

### 克隆

```bash
git svn init http://ip/svn/demo/trunk demo
git svn fetch -r HEAD

或者

git svn clone http://ip/svn/demo/trunk -s --prefix=svn/
```

clone执行Runs init and fetch

* -s 告诉 Git 该 Subversion 仓库遵循了基本的分支和标签命名法则，也就是标准布局。如果你的主干(trunk，相当于非分布式版本控制里的master分支，代表开发的主线），分支(branches)或者标签(tags)以不同的方式命名，则应做出相应改变。  
-s参数其实是-T trunk -b branches -t tags的缩写，这些参数告诉git这些文件夹与git分支、tag、master的对应关系。
* --prefix=svn/ 给svn的所有remote名称增加了一个前缀svn，这样比较统一，而且可以防止warning: refname 'xxx' is ambiguous.

### 只下载指定版本之后的历史

```bash
git svn clone -r<开始版本号>:<结束版本号> <svn项目地址> [其他参数]

例：
git svn clone -r2:HEAD file:///d/Projects/svn_repo proj1_git -s
```

其中2为svn版本号，HEAD代表最新版本号，就是只下载svn服务器上版本2到最新的版本的代码

### 更新

```bash
git svn rebase
```

从svn上更新代码, 相当于svn的update

### 提交

```bash
git svn dcommit
```

提交commit到svn远程仓库，建议提交前都先运行下git svn rebase
