---
title: win10编译ffmpeg7
date: 2024-10-28 14:32:17
tags:
---

win10环境下编译ffmpeg需要msys2环境，建议在msys2的环境中采用MSVC进行编译，可直接编译出.lib文件和.dll动态库。预先安装msys2和visual studio环境。
再安装ffmpeg7相关的库，步骤如下：

1. 安装和编译必要的依赖项以及x264、x265和sdl

   ```sh
   pacman -S diffutils make pkg-config yasm
   ```

   note: 列出孤立的包（-t不再被依赖的"作为依赖项安装的包"）

   ```sh
   pacman -Qqdt
   ```

   注意：这些通常是可以删除的。(sudo pacman -Qqdt | sudo pacman -Rs -)

   先从开始菜单找到Visual Studio Command line，选择“x64 Native Tools Command Prompt for VS”，然后在命令行执行：

   ```bat
   call msys2_shell.cmd -mintty -mingw64 -no-start -here -use-full-path
   ```

   note: 执行msys2目录中的msys2_shell.cmd批处理，注意`加上 -use-full-path` 使 msys2 的环境变量继承当前CMD的窗口的环境变量。
   然后在打开的mintty中编译ffmpeg。

   编译 x264
   编译当前最新x264时需要用到nasm

   ```sh
   pacman -S nasm
   git clone --depth=1 https://code.videolan.org/videolan/x264.git
   ./configure --prefix=/d/ops/ffmpeg --enable-shared
   make -j 8 && make install
   mv /d/ops/ffmpeg/lib/libx264.dll.lib /d/ops/ffmpeg/lib/libx264.lib
   ```

   编译 x265
   下载源码

   ```sh
   git clone --depth=1 https://bitbucket.org/multicoreware/x265_git.git
   cd x265_git/build/msys-cl
   ```

   进入 x265_git/build/msys-cl 目录，修改make-Makefiles.sh为：

   ```sh
    INSTALL_DIR="/d/ops/ffmpeg"

    if cl; then
        echo 
    else
        echo "please launch msys from 'visual studio command prompt'"
        exit 1
    fi

    cmake -G "NMake Makefiles" -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR -DCMAKE_CXX_FLAGS="-DWIN32 -D_WINDOWS -W4 -GR -EHsc" -DCMAKE_C_FLAGS="-DWIN32 -D_WINDOWS -W4"  ../../source

    if [ -e Makefile ]
    then
        nmake
    fi

    nmake install
   ```

   添加了如下三行：

   ```sh
   INSTALL_DIR="/d/ops/ffmpeg"
   -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR
   nmake install
   ```

   运行make-Makefiles.sh进行编译和安装

   ```sh
   ./make-Makefiles.sh
   ```

   将 /d/ffmpeg/lib/libx265.lib， 改名位x265.lib。编译ffmpeg时查找的库名为x265.lib。

2. 安装 sdl
   因为要生产 ffplay，而 ffplay 需要 sdl，所以要下载 sdl2 并安装，地址: https://github.com/libsdl-org/SDL/releases/latest
   下载 VC 版，解压。在 lib 目录里面添加 pkgconfig 文件夹，在里面创建 sdl2.pc 文件，内容如下:

   ```
    prefix=/d/ops/sdl2
    exec_prefix=${prefix}
    libdir=${prefix}/lib/x64
    includedir=${prefix}/include

    Name: sdl2
    Description: Simple DirectMedia Layer is a cross-platform multimedia library designed to provide low level access to audio, keyboard, mouse, joystick, 3D hardware via OpenGL, and 2D video framebuffer.
    Version: 2.30.8
    Requires:
    Conflicts:
    Libs: -L${libdir} -lSDL2main -lSDL2
    Cflags: -I${includedir}
   ```

3. 配置 ffmpeg

   进入 ffmpeg 目录将如下代码保存为.sh文件并执行

   ```sh
   X264_INSTALL="/d/ops/ffmpeg"
   X265_INSTALL="/d/ops/ffmpeg"
   SDL_INSTALL="/d/ops/sdl2"

   X264_INCLUDE=$X264_INSTALL/include
   X264_LIB=$X264_INSTALL/lib
   X264_BIN=$X264_INSTALL/bin

   X265_INCLUDE=$X265_INSTALL/include
   X265_LIB=$X265_INSTALL/lib
   X265_BIN=$X265_INSTALL/bin

   SDL_INCLUDE=$SDL_INSTALL/include
   SDL_LIB=$SDL_INSTALL/lib/x64
   SDL_BIN=$SDL_INSTALL/lib/x64

   export PATH=$X264_BIN:$PATH
   export PATH=$X265_BIN:$PATH
   export PATH=$SDL_BIN:$PATH

   ## export INCLUDE=$INCLUDE:$SDL_INCLUDE
   ## export LIB=$LIB:$SDL_LIB

   export PKG_CONFIG_PATH=$X264_LIB/pkgconfig:$PKG_CONFIG_PATH
   export PKG_CONFIG_PATH=$X265_LIB/pkgconfig:$PKG_CONFIG_PATH
   export PKG_CONFIG_PATH=$SDL_INSTALL/lib/pkgconfig:$PKG_CONFIG_PATH

   echo $PKG_CONFIG_PATH
   echo $LIB

   INSTALL_DIR="/d/ops/ffmpeg"

   OPTIONS="--toolchain=msvc
           --enable-yasm
           --enable-asm
           --enable-shared
           --disable-programs
           --enable-swresample
           --enable-swscale
           --enable-gpl
           --enable-libx264
           --enable-libx265
           --enable-ffmpeg
           --enable-sdl2
           --enable-ffplay
           "

   CC=cl ./configure $OPTIONS --prefix=$INSTALL_DIR/
   ```

   note: `不要export LIB，否则会链接VC的lib出错。`

   ```sh
   make -j 8 && make install
   make clean
   ```

   如果编译出错，报`fftools/opt_common.c(206): warning C4129: “l：: 不可识别的字符转义序列`，修改config.h文件编码为utf-8，继续编译。
   或者把 config.h 中的中文改成英文。
