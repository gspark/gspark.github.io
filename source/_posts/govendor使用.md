---
title: govendor使用
date: 2018-04-02 17:16:56
tags: go
---
# govendors使用

[govendor](https://github.com/kardianos/govendor) 是golang依赖包管理工具之一。

## 环境变量

GOROOT: go的安装路径,官方包路径根据这个设置自动匹配

GOPATH: 工作路径，主要包含三个目录: bin、pkg、src  
go中是没有项目这个概念的，只有包。可执行包只是特殊的一种，类似我们常说的项目 GOPATH 可以设置多个，不管是可执行包，还是非可执行包，通通都应该在某个`$GOPATH/src` 下，比如可以把你的可执行(项目)包，安放在某个 `$GOPATH/src` 下，例如 `$GOPATH/src/app/example.com`，这样本地包的import就变成:

```go
import "app/example.com/subpackage"
```

这样使用 GOPATH 的好处：

1. 可以使用 `go install` 你的子包，有利于 go build 的时间，如果子包较大，那就更明显了。
2. [gocode](https://github.com/nsf/gocode) 的自动完成可以用了。  
   gocode windows安装
   `go get -u -ldflags -H=windowsgui github.com/nsf/gocode`

## 安装

### 安装指令

go get -u github.com/kardianos/govendor

### 设置

包含vendor文件夹的代码路径应该在GoPath路径下：

```bat
$GOPATH/src/
   example.com/
     main.go
   vendor/
     github.com/
       spf13/viper/
       gizak/termui/
```

如上面的例子，example.com为工程文件夹，main.go 和 vendor 在此目录下，为同一级。

### 配置文件 vendor.json

配置文件 vendor.json 中的 rootPath 是指 `$GOPATH/src` 下的路径，例如：

``` json
"rootPath": "services/example.com"
```

路径是：
```bat
$GOPATH/src/
   services/example.com

```

## 使用

参考 [govendor](https://github.com/kardianos/govendor) 文档。
