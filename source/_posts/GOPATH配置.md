---
title: GOPATH配置
date: 2018-04-19 11:40:16
tags: go
---
# GOPATH配置

GOPATH是用来放自己的GO工程的。一般该目录下有三个文件夹：src、bin、pkg。环境变量`%GOPATH%`中可配置多个路径，中间用`;`隔开。

## 安装go依赖包

go依赖的包比较多，有些包不好下载，写了个批处理来下载。

```bat
@set TOOLS_DIR=%GOPATH%\src\golang.org\x\tools
@set ORIGIANL_DIR=%CD%

IF NOT EXIST "%TOOLS_DIR%" (
    echo clone tools
    call git clone --progress -v "https://github.com/golang/tools.git" "%TOOLS_DIR%"
) ELSE (
    echo updating tools
    chdir /d "%TOOLS_DIR%"
    call git pull
    echo "%ORIGIANL_DIR%"
    chdir /d "%ORIGIANL_DIR%"
)

@set LINT_DIR=%GOPATH%\src\golang.org\x\lint
IF NOT EXIST "%LINT_DIR%" (
    echo clone lint
    call git clone --progress -v "https://github.com/golang/lint.git" "%LINT_DIR%"
) ELSE (
    echo updating lint
    chdir /d "%LINT_DIR%"
    call git pull
    echo "%ORIGIANL_DIR%"
    chdir /d "%ORIGIANL_DIR%"
)

echo go getting...

:: 代码自动提示 
go get -u -v github.com/nsf/gocode
:: 代码之间跳转 
go get -u -v github.com/rogpeppe/godef
:: 搜索参考引用
go get -u -v github.com/lukehoban/go-find-references 

:: go get -u -v github.com/lukehoban/go-outline
go get -u -v github.com/ramya-rao-a/go-outline

:: The Vendor Tool for Go
go get -u -v github.com/kardianos/govendor

:: delve调试工具 for vscode
go get -u -v github.com/derekparker/delve/cmd/dlv

:: 语法检查
go get -u -v github.com/golang/lint/golint
:: go get -u -v golang.org/x/lint/golint

go get -u -v github.com/uudashr/gopkgs/cmd/gopkgs

go get -u -v github.com/acroca/go-symbols

go get -u -v golang.org/x/tools/cmd/goimports

go get -u -v golang.org/x/tools/cmd/gorename

go get -u -v github.com/sqs/goreturns

go get -u -v golang.org/x/tools/cmd/guru

go get -u -v github.com/cweill/gotests/...

```

批处理文件 [点击下载](/download/GOPATH配置/golang-tools.bat)

## 多工程GOPATH

GOPATH 表示工作区路径，如果有多个工作区该如何配置呢？全局一个 GOPATH 和 每个项目一个单独的 GOPATH, 各有优缺点。目前采用的是每项目一个 GOPATH，在环境变量 GOPATH 里面添加多个项目路径。

采用 govendor 做包管理，要注意 vendor.json 中 rootPath 的设置，例如："rootPath": "shadowsocksR"， 则表示 vendor 文件夹路径为`%GOPATH%\src\shadowsocksR`。
