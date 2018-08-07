---
title: Shell多进程并发控制
date: 2017-10-25
categories: Shell
tags:
- Shell
- 多进程
- 并发
---

每个进程的任务就是等待10秒，进程任务完成之后再启动一个新的进程，保证并发数是8。
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
