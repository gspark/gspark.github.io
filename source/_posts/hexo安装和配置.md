---
title: hexo安装和配置
date: 2018-02-24 14:40:19
tags:
---
# hexo安装和配置

## hexo简介

Hexo是一个快速、简洁且高效的博客框架，支持Markdown格式，有众多优秀插件和主题。

官网： <http://hexo.io>
github: <https://github.com/hexojs/hexo>

## 安装

先安装node.js，安装完成后再执行

```bat
npm install -g hexo
```

## 初始化

新建一个文件夹（名字如：hexo，可以随便取），由于这个文件夹将来就作为你存放代码的地方，所以最好不要随便放。进入那个目录

```bat
hexo init
```

hexo会自动下载一些文件到这个目录，包括node_modules。

```bat
hexo g
```

在public目录生成相关html文件。

```bat
hexo s
```

开启本地预览服务，打开浏览器访问 `http://localhost:4000` 即可看到内容。

## 修改主题

默认主题不好看，改用next主题，[hexo-theme-next](https://github.com/theme-next/hexo-theme-next)。
首先安装主题

```bat
cd hexo
git clone https://github.com/theme-next/hexo-theme-next themes/next
```

主题都安装到themes目录中。
然后修改hexo目录中_config.yml文件，将其中的theme: landscape改为theme: next，然后重新执行hexo g来重新生成。

## 传到github

如果github pages服务都配置好了，发布上传很容易，一句hexo d就搞定。
其次，配置_config.yml中有关deploy的部分：

```yaml
deploy:
  type: git
  repo: https://github.com/gspark/gspark.github.io.git
  branch: master
```

直接执行hexo d的话一般会报如下错误：

```bat
Deployer not found: github
```

或者

```bat
Deployer not found: git
```

原因是还需要安装一个插件：

```bat
npm install hexo-deployer-git --save
```

## 原始md文件管理

hexo生成的静态页面上传github后，原始的md文件也需要版本管理：
对自己的xxx.github.io仓库打一个分支，如hexo，再把hexo目录下对应的代码文件和配置文件上传到这个分支即可。以后再分支上进行md文件的增、删、改、查和对配置文件的修改。

## 配置

### 资源文件配置

通过将 config.yml 文件中的 post_asset_folder 选项设为 true 来打开。

```yaml
_config.yml
    post_asset_folder: true
```

当资源文件管理功能打开后，Hexo将会在你每一次通过 `bat hexo new [layout] <title>` 命令创建新文章时自动创建一个文件夹。这个资源文件夹将会有与这个 markdown 文件一样的名字。将所有与你的文章有关的资源放在这个关联文件夹中之后，你可以通过相对路径来引用它们，这样你就得到了一个更简单而且方便得多的工作流。

### 图片路径

hexo博客图片的问题在于，markdown文章使用的图片路径和hexo博客发布时的图片路径不一致。
可使用[CodeFalling/hexo-asset-image](https://github.com/CodeFalling/hexo-asset-image)插件来解决。
在hexo的目录下执行

```bat
npm install https://github.com/CodeFalling/hexo-asset-image --save
```

只要使用

```markdown
![](本地图片测试/logo.jpg)
```

就可以插入图片。其中[]里面不写文字则没有图片标题。