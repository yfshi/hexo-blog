---
title: gdb
date: 2017-10-23
tags: gdb
---

# 信号处理

gdb对信号处理有三类动作：停止、打印、传给程序。



```shell
info handle # 查看所有信号的处理方式
handle SIGUSR2 nostop noprint pass #设置信号处理方式
```

| 动作    | 解释                 |
| ------- | -------------------- |
| print   | 收到信号打印         |
| noprint | 收到信号不打印       |
| stop    | 收到信号中断         |
| notop   | 收到信号不中断       |
| pass    | 收到信号传递给程序   |
| nopass  | 收到信号不传递给程序 |

# 设置源代码路径

在A机器上gcc编译的执行文件test，放到B机器去执行。在B机器上gdb调试test，怎么在gdb中查看源代码。

有两种方法：

1. 把代码放到编译机完全相同的路径

   ```shell
   # readelf -P .debug_str test
   # mkdir <code_dir>
   ```

2. 使用gdb的substitute-path映射功能

   ```shell
   # readelf -P .debug_str test
   # gdb ./test
   (gdb) set substitute-path <source_dir> <current_dir>
   (gdb) list
   ```

# 多进程调试

set follow-fork-mode [parent | child]

set detach-on-fork [on|off]

# 多线程调试

调试多线程时，有时需要控制某些线程停在断点，有些线程继续执行。有时需要控制线程的运行顺序。有时需要中断某个线程，切换到其他线程。这些都可以通过gdb实现。

gdb调试线程的常用命令如下：

| gdb命令                           | 描述                                                         |
| --------------------------------- | ------------------------------------------------------------ |
| info thread                       | 显示所有线程                                                 |
| thread ID                         | 切换到ID指定的线程                                           |
| break xxx.c:10 thread all         | 所有线程都在xxx.c文件的第10行断点，all可以换成单个线程ID     |
| thread apply all COMMON           | 所有线程都执行COMMOND命令，也可以把all换成单个线程ID         |
| set scheduler-locking off/on/step | 在调试某一线程时，其他线程是否执行。off：不锁定任何线程，默认值。on：锁定其他线程，只有当前线程运行。step：在step单步调试时，只有被调试线程运行。 |
| set non-stop on/off               | 当调试一个线程时，其他线程是否运行。默认off。                |
| set pagination on/off             | 在使用backtrace时，在分页时是否停止。默认on。                |
| set target-async on/off           | 同步和异步。同步，gdb在输出提示符之前等待程序报告一些线程已经终止的信息。而异步的则是直接返回。默认off。 |

non-stop模式调试后台程序：

```shel
$ gdb
(gdb) set non-stop on
(gdb) set pagination off
(gdb) set target-async on
(gdb) attach 82373
(gdb) info thread
(gdb) thread apply all continue &
(gdb) thread 10
(gdb) continue &
```

注意：在使用non-stop模式调试时，凡是执行continue操作时最好加上&放入后台。否则如果continue之后当前线程没有产生断点，则回不到交互模式。

# 打印相关

```shell
set print address -- Set printing of addresses
set print array -- Set prettyprinting of arrays
set print array-indexes -- Set printing of array indexes
set print asm-demangle -- Set demangling of C++/ObjC names in disassembly listings
set print demangle -- Set demangling of encoded C++/ObjC names when displaying symbols
set print elements -- Set limit on string chars or array elements to print
set print frame-arguments -- Set printing of non-scalar frame arguments
set print inferior-events -- Set printing of inferior events (e.g.
set print max-symbolic-offset -- Set the largest offset that will be printed in <symbol+1234> form
set print null-stop -- Set printing of char arrays to stop at first null char
set print object -- Set printing of object's derived type based on vtable info
set print pascal_static-members -- Set printing of pascal static members
set print pretty -- Set prettyprinting of structures
set print repeats -- Set threshold for repeated print elements
set print sevenbit-strings -- Set printing of 8-bit characters in strings as \nnn
set print static-members -- Set printing of C++ static members
set print symbol-filename -- Set printing of source filename and line number with <symbol>
set print thread-events -- Set printing of thread events (such as thread start and exit)
set print union -- Set printing of unions interior to structures
set print vtbl -- Set printing of C++ virtual function tables
```

# LIBRARY_PATH与LD_LIBRARY_PATH

`LIBRARY_PATH`环境变量用于在程序编译期间查找动态链接库时指定查找共享库的路径。如果不指定`LIBRARY_PATH`，可以在gcc编译时通过-L指定共享库路径。

`LD_LIBRARY_PATH`环境变量用于在程序加载运行期间查找动态链接库时指定除了系统默认路径之外的其他路径。注意，`LD_LIBRARY_PATH`中指定的路径会在系统默认路径之前进行查找。

设置方法都是通过`export`命令。

```bash
export LIBRARY_PATH=`pwd`:$LIBRARY_PATH
export LD_LIBRARY_PATH=`pwd`:$LIBRARY_PATH
```
