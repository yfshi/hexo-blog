---
layout: post
title: Shell
date: 2017-10-23
tags: 
- shell
categories: Shell
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

# 变量的间接引用 ${!var}
即以变量名作为新的变量，取新变量的值
```bash
function test() {
	v=$1
	echo ${!v}
}
x=10
test x
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

```bash
#!/bin/bash

DBHOME="$GPHOME"
UPDATEFILE=""
HOSTFILE=""

ROOTDIR=`pwd`
BASEDIR=$(cd `dirname $0`; pwd)
PROGRAM=${0##*/}

Usage() {
	echo "$PROGRAM is a local dongle update tool."
	echo
	echo "Usage:"
	echo "  $PROGRAM [OPTION] UPDATEFILE"
	echo
	echo "Options:"
	echo "  -d DBHOME         Database installation path, default \"\$GPHOME\"."
	echo "  -f HOSTFILE       This specifies the file that lists the hosts"
	echo "                    onto which you want to install Greenplum Database."
}

# show help
if [ "x$1" = "x--help" ] || [ "x$1" = "x-?" ]; then
	Usage
	exit 0
fi

while getopts "d:f:" opt;
do
	case $opt in
		d)
			DBHOME=$OPTARG
			;;
		f)
			HOSTFILE=$OPTARG
			;;
		?)
			echo "Invalid options: -$OPTARG"
			exit 1;;
	esac
done

# UPDATEFILE
eval UPDATEFILE="$""$OPTIND"
```



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

* 例子

```bash
#!/bin/bash

# 把标准输出和标准错误绑定到指定文件，并使用两个临时描述符变量保存标准输出和标准错误，用于恢复
openlog() {
	file=$1
	exec 6>&1     # 把6绑定到标准输出，即把标准输出1复制到6
	exec 7>&2     # 把7绑定到标准错误
	exec 1>$file  # 把标准输出绑定到文件  exec 1>$file 是绑定追加
	exec 2>$file  # 把标准错误绑定到文件
}

# 恢复标准输出和标准错误，关闭临时描述符6和7
closelog() {
	exec 1>&6 6>&-
	exec 2>&7 7>&-
}

openlog logfile

echo "=================="
ls /proc/self/fd
echo "=================="
echo "hello"
echo "world"

closelog

echo "=================="
ls /proc/self/fd
echo "=================="
echo "111"
```

# 多进程

如下，每个进程的任务就是等待10秒，进程任务完成之后再启动一个新的进程，保证并发数是8。
通过命名管道控制进程数量。

```bash
#!/bin/bash

tmpfifo=$$.fifo

trap "exec 1000>&-;exec 1000<&-;exit 0" 2 3 15

mkfifo $tmpfifo
exec 1000<>$tmpfifo
rm -f $tmpfifo

for ((i=1;i<=8;i++))
do
	echo >&1000
done

while true
do
	let t++
	read -u 1000
	{
		sleep 10
		echo >&1000
	} &
done

wait

echo "done!!!"
```

# 格式判断

```bash
#!/bin/bash

check_format() {
    local type=$1
    local var=$2
    local ret=0

    [ $# -ne 2 ] && return 1

    case $type in
        "STRING")
            [ "x$var" = "x" ] && ret=2
            ;;  
        "NUMBER")
            echo $var | grep -Ev '^[0-9]{1,}$' > /dev/null 2>&1 && ret=2
            ;;  
        *)  
            ret=2
    esac

    return $ret
}

[ `check_format NUMBER asdfsa` -ne 0 ] && exit 1

exit 0
```

# 字符串处理

## 字符串分割

shell如何用指定的分隔符来分割字符串为一个数组？这里介绍两种方法

方法一

```bash
#!/bin/bash
string="hello,shell,word"
array=(${string//,/ })
for var in ${array[@]}
do
	echo $var
done
```

方法二

```bash
#!/bin/bash
string="hello,shell,word"
OLD_IFS="$IFS"
IFS=","
array=($string)
IFS="$OLD_IFS"
for var in ${array[@]}
do
	echo $var
done
```

## 字符串截取

| 格式                     | 说明                                                         |
| :----------------------- | :----------------------------------------------------------- |
| ${string:start:length}   | 从 string 字符串的左边第 start 个字符开始，向右截取 length 个字符。 |
| ${string:start}          | 从 string 字符串的左边第 start 个字符开始截取，直到最后。    |
| ${string:0-start:length} | 从 string 字符串的右边第 start 个字符开始，向右截取 length 个字符。 |
| ${string:0-start}        | 从 string 字符串的右边第 start 个字符开始截取，直到最后。    |
| ${string#*chars}         | 从 string 字符串第一次出现 *chars 的位置开始，截取 *chars 右边的所有字符。 |
| ${string##*chars}        | 从 string 字符串最后一次出现 *chars 的位置开始，截取 *chars 右边的所有字符。 |
| ${string%chars*}         | 从 string 字符串第一次出现 *chars 的位置开始，截取 *chars 左边的所有字符。 |
| ${string%%chars*}        | 从 string 字符串最后一次出现 *chars 的位置开始，截取 *chars 左边的所有字符。 |

### 从指定位置开始截取

```bash
${string:start:length}
${string:0-start:length}
```

string是要截取的字符串，start是起始位置，length是要截取的长度（省略表示直到字符串的末尾）。

注意：

1. 从左边开始计数，其实数字是0；从右边开始计数，其实数字是1。
2. 不管从哪边开始计数，截取方向都是从左到右。

例：

```bash
#!/bin/bash

url="abcdefghijklmn"
echo ${url:2}
echo ${url:5:3}       
echo ${url:0-3}
echo ${url:0-10:5}
```

输出：

```bash
cdefghijklmn
fgh
lmn
efghi
```

### 从指定字符串开始截取

这种截取方式无法指定长度，只能从指定字符串截取到字符串末尾。可以截取指定字符串右边的所有字符，也可以截取左边的所有字符。

```bash
${string#*chars}
${string##*chars}
${string%chars*}
${string%%chars*}
```

其中，string是要截取的字符串，chars是指定的字符串，`*`是通配符的一种，表示任意长度的字符串。`*chars`连起来使用的意思是忽略左边的所有字符，知道遇见chars。

例：

```bash
#!/bin/bash

url="1234123412341234"
echo ${url#*23}
echo ${url##*23}
echo ${url%23*}
echo ${url%%23*}
```

# ssh

```bash
$ ssh -T -o StrictHostKeyChecking=no <<EOF
# 不允许定义和使用变量，可以读取外部变量，不能给外部变量赋值
# 可以定义函数，函数内部不能使用变量和参数，不能使用外部函数
# 此处执行子shell无效，等同与在ssh之外执行，如`ls`和$(ls)
EOF
```

