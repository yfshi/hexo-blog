---
title: hostname的那点事
date: 2017-09-19
tags: hostname
categories: 操作系统
---

# hostname的本质

hostname是Linux下的一个内核参数,保存在/proc/sys/kernel/hostname下,它的值是Linux启动时从rc.sysinit读取的.而/etc/rc.d/rc.sysinit中HOSTNAME的取值来自于/etc/sysconfig/network下的HOSTNAME.

> Linux的启动过程:
1. 加载BIOS
2. 读取MBR
3. Boot Loader / Grup
4. 加载内核
5. 用户层init依据inittab文件来设定运行等级
6. init进程执行rc.sysinit
7. 启动内核驱动模块
8. 执行不同运行级别的脚本程序(/etc/rc.d/rc$RUNLEVEL)
9. 执行/etc/rc.d/rc.local
10. 执行/bin/login程序,进入登录状态

/etc/sysconifg/network内容如下:

```bash
NETWORKING=yes
HOSTNAME==server-111
```

/etc/rc.d/rc.sysinit相关代码如下:

```bash
......
HOSTNAME=$(/bin/hostname)

set -m

if [ -f /etc/sysconfig/network ]; then
    . /etc/sysconfig/network
fi
if [ -z "$HOSTNAME" -o "$HOSTNAME" = "(none)" ]; then
    HOSTNAME=localhost
fi
......
# Set the hostname.
update_boot_stage RChostname
......
```

# 修改hostname

修改hostname有几种方式:

1. `hostname DB-Server` \-\- 运行后立即生效(新会话生效),系统重启后会丢失所做的修改
2. `echo DB-Server > /proc/sys/kernel/hostname` \-\- 运行后立即生效(新会话生效),系统重启后会丢失所做的修改
3. `sysctl kernel.hostname=DB-Server` \-\- 运行后立即生效(新会话生效),系统重启后会丢失所做的修改
4. 修改`/etc/sysconfig/network`下的`HOSTNAME`变量 \-\- 需重启系统生效,永久性修改

修改了hostname后,如何使其立即生效而不用重启操作系统？  

先按照步骤四修改,然后从前3步中任选一个执行

# hostname与/etc/hosts

hosts的作用相当于DNS,提供IP地址到hostname的对应.早期的互联网计算机数量少,单机hosts文件里足够存放所有联网计算机.不过随着互联网的发展,这就远远不够了.于是就出现了分布式的DNS系统.由DNS服务器来提供类似的IP地址到域名的对应.具体可以man hosts查看相关信息.

Linux系统在向DNS服务器发出域名解析请求之前会查询/etc/hosts文件,如果里面有相应的记录,就会使用hosts里面的记录.
/etc/hosts文件通常里面包含这一条记录127.0.0.1 localhost.localdomain localhost.hosts文件格式是一行一条记录,分别是IP地址、hostname、aliases,三者用空白字符分隔,aliases可选.

127.0.0.1到localhost这一条建议不要修改,因为很多应用程序会用到这个,比如sendmail,修改之后这些程序可能就无法正常运行.

但是,其实hostname也不是说跟/etc/hosts一点关系都没有.在/etc/rc.d/rc.sysinit中,有如下逻辑判断,当hostname为localhost后localhost.localdomain时,将会使用接口IP地址对应的hostname来重新设置系统的hostname.
