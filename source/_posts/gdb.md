---
title: gdb
date: 2017-10-23
tags: gdb
---

# LIBRARY_PATH与LD_LIBRARY_PATH

`LIBRARY_PATH`环境变量用于在程序编译期间查找动态链接库时指定查找共享库的路径。如果不指定`LIBRARY_PATH`，可以在gcc编译时通过-L指定共享库路径。

`LD_LIBRARY_PATH`环境变量用于在程序加载运行期间查找动态链接库时指定除了系统默认路径之外的其他路径。注意，`LD_LIBRARY_PATH`中指定的路径会在系统默认路径之前进行查找。

设置方法都是通过`export`命令。

```bash
export LIBRARY_PATH=`pwd`:$LIBRARY_PATH
export LD_LIBRARY_PATH=`pwd`:$LIBRARY_PATH
```
