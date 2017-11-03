---
layout: post
title: 'shell'
date: '2017-10-23'
categories: 'shell'
tags: ''
---

# `--`

shell内置命令，表示选项的结束，也就是说后面都是参数，不在有选项。主要是为了避免后面的参数以`-`开头的时候被识别为选项。

```bash
cat "abc-Rdef" | grep -R
cat "abc-Rdef" | grep -- -R
```

删除以‘-’开头的文件

```bash
rm -f -f
rm -f -- -f
```

# `-`

`tar -cvf - * | tar -xvf - -C /tmp`复制当前目录并且时间不变。

# eval

eval解析两次，第一次替换变量，第二次执行。

```bash
a="ls -l"
eval $a
```

# getopt与getopts

getopt可以处理unix和GNU格式的参数。

```bash
#!/bin/bash

GETOPT_ARGS=`getopt -o abc:d::e -al aaa,bbb,ccc:,ddd::,eee -- "$@"`
eval set -- "$GETOPT_ARGS"

echo "after getopt: $0 $@"

while [ -n "$1" ]
do
	case $1 in
		-a|--aaa) echo "option $1"; shift;;
		-b|--bbb) echo "option $1"; shift;;
		-c|--ccc) echo "option $1 $2"; shift 2;;
		-d|--ddd)
			case $2 in
				"") echo "option $1"; shift 2;;
				*) echo "option $1 $2"; shift 2;;
			esac
			;;
		-e|--eee) echo "option $1"; shift;;
		--) shift; break;;
		*) echo "unknown: $1"; exit 1;;
	esac
done
```

getopts处理unix格式的参数。

```bash
#!/bin/bash

while getopts abc:d:e opt
do
	case "$opt" in
		a) echo "-a";;
		b) echo "-b";;
		c) echo "-c $OPTARG";;
		d) echo "-d $OPTARG";;
		e) echo "-e";;
		*) echo "unkown"
			exit 2;;
	esac
done
```

上面是一段shell中命令行处理的实现。

# exec与文件描述符

对于Linux而言，所有对设备和文件的操作都使用文件描述符来进行的。
通常，一个进程启动时，会打开3个文件描述符：标准输入、标准输出、标准错误。对应的描述符分别是0、1、2。

* exec分配文件描述符

```bash
exec 6<>hello.txt   # 以读写方式绑定文件到描述符6
echo "hello" >&6    # 写入“hello”，这里将会从文件开头进行覆盖
echo "world" >&6    # 写入“world”，新的一行
exec 6>&-           # 关闭写，实际上也不能读了
exec 6<&-           # 关闭读，实际上也不能写了
```

* 输出重定向

```bash
exec 1>hello.txt    # 将标准输出重定向到文件，从此之后该进程的输出都将被写入”hello.txt“
echo "hello"
echo "wolrd"
```

* 恢复重定向

```bash
exec 100>&1
exec 1>hello.txt
echo "hello"
echo "world"
exec 1>&100 100>&-
echo "reset"
```

* 输入重定向

```bash
exec 100<&0
exec <hello.txt
read $line1
echo $line1
read $line2
echo $line2
exec 0<&100 100>&-
read $line3
```
