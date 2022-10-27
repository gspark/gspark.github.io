---
title: >-
  std::numeric_limits<int>::max() error C2589: '(' : illegal token on right side
  of '::' 处理
date: 2022-10-21 15:31:29
tags: c++
---

const unsigned int maxUnitSize =
            unitCodes.count(maxUnit) > 0 ? unitCodes.at(maxUnit) : std::numeric_limits<unsigned int>::max();
编译的时候报错：

```sh
warning C4003: not enough actual parameters for macro 'max'
error C2589: '(' : illegal token on right side of '::'
error C2059: syntax error : '::'·
```

原因是STL的numeric_limits::max()和VC min/max 宏冲突问题。

解决方法是通过括号“（）”来避免预编译器报错。修改为:
const unsigned int maxUnitSize =
            unitCodes.count(maxUnit) > 0 ? unitCodes.at(maxUnit) : (std::numeric_limits<unsigned int>::max)();

