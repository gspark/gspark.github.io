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
