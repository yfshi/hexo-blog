---
layout: _post
title: Greenplum安装
date: 2018-07-10 19:40:00
tags:
- PostgreSQL
- Greenplum
categories: Greenplum
---

节点分配：

| 地址       | 主机名 | segment       | mirror       |
| ---------- | ------ | ------------- | ------------ |
| 10.0.0.100 | gp     | master        |              |
| 10.0.0.101 | gp1    | pseg0、pseg1  | mseg4、mseg5 |
| 10.0.0.102 | gp2    | pseg2、gpseg3 | mseg0、mseg1 |
| 10.0.0.103 | gp3    | pseg4、pseg5  | mseg2、mseg3 |
| 10.0.0.104 | gps    | standby       |              |

# 操作系统

本章所有操作在所有节点使用root用户执行

## 开发环境

当前系统如下：

```shell
$ cat /etc/issue
CentOS release 6.4 (Final)
Kernel \r on an \m

$ uname -a
Linux vm 2.6.32-358.el6.x86_64 #1 SMP Fri Feb 22 00:31:26 UTC 2013 x86_64 x86_64 x86_64 GNU/Linux
```

搭建基本环境：

```shell
# linux基本环境
$ yum install -y bzip2 cmake gcc gcc-c++ gdb git libtool lrzsz make man net-tools sysstat unzip vim wget zip

# 数据库开发环境
$ yum install -y apr-devel apr-util-devel bison bzip2-devel c-ares-devel flex java-1.8.0-openjdk java-1.8.0-openjdk-devel json-c-devel krb5-devel libcurl-devel libevent-devel libkadm5 libxml2-devel libxslt-devel libyaml-devel openldap-devel openssl-devel pam-devel perl perl-devel perl-ExtUtils-Embed readline-devel unixODBC-devel zlib-devel
```

如果上述环境无法满足要求，参考[Greenplun编译](../Greenplum编译/)

## 系统设置

```shell
# 关闭防火墙
$ service iptables stop
$ chkconfig iptables off

# 禁用selinux
$ setenforce 0
$ vi /etc/selinux/config
SELINUX=disabled

# 分别配置ip
$ bash -c 'cat > /etc/sysctl.conf <<-EOF
DEVICE=eth0
TYPE=Ethernet
ONBOOT=yes
BOOTPROTO=static
IPADDR=10.0.0.100
NETMASK=255.255.255.0
EOF'

# 分别设置主机名
$ vi /etc/sysconfig/network
NETWORKING=yes
HOSTNAME=gp
```

## 系统参数配置

```shell
$ cat >> /etc/sysctl.conf <<-EOF
kernel.shmmax = 500000000
kernel.shmmni = 4096
kernel.shmall = 4000000000
kernel.sem = 500 1024000 200 4096
kernel.sysrq = 1
kernel.core_uses_pid = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.msgmni = 2048
net.ipv4.tcp_syncookies = 1
net.ipv4.ip_forward = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.conf.all.arp_filter = 1
net.ipv4.ip_local_port_range = 1025 65535
net.core.netdev_max_backlog = 10000
net.core.rmem_max = 2097152
net.core.wmem_max = 2097152
vm.overcommit_memory = 2
EOF

$ cat >> /etc/security/limits.conf <<-EOF
* soft nofile 65536
* hard nofile 65536
* soft nproc 131072
* hard nproc 131072
EOF

$ cat >> /etc/ld.so.conf <<-EOF
/usr/local/lib
EOF
```

## 添加主机名本地映射

```shell
$ cat >> /etc/hosts <<-EOF
10.0.0.100  ka
10.0.0.101  ka1
10.0.0.102  ka2
10.0.0.103  ka3
10.0.0.104  kas
EOF
```

## 重启操作系统

上述所有配置完成之后重启操作系统。

如果是在虚拟机操作，创建快照，方便以后恢复。另外，如果是虚拟机操作，只需配置一台机器，然后克隆其他的机器，修改ip和主机名即可。

# 安装Greenplum

## 添加用户

```shell
$ useadd gpadmin
$ passwd gpadmin
$ vi /etc/sudoers
gpadmin ALL=(ALL) NOPASSWD: ALL
```

以下操作都在主节点的gpadmin用户下进行

## 创建节点文件

创建两个文件：all_hosts和all_segs，all_hosts是所有节点列表，all_segs是所有segment所在的节点列表。

```shell
$ cat all_hosts
gp
gp1
gp2
gp3
gps
$ cat all_segs
gp1
gp2
gp3
```

## 配置主机互信

交换密钥

```shell
$ source /home/gpadmin/gpdb/Greenplum_path.sh
$ gpssh-exkeys -f all_hosts
```

## 安装

* master节点安装Greenplum到/home/gpadmin/gpdb

  略

* 把master的Greenplum同步安装到其他机器

  ```shell
  $ source /home/gpadmin/gpdb/Greenplum_path.sh
  $ gpseginstall -f all_hosts
  ```

# 初始化Greenplum

修改配置文件

```shell
$ cp /home/gpadmin/gpdb/docs/cli_help/gpconfigs/gpinitsystem_config .

# 修改为如下配置，各个参数的意义参考注释
$ cat gpinitsystem_config | grep -E -v '^#' | grep -v '^$'
ARRAY_NAME="Greenplum Data Platform"
SEG_PREFIX=gpseg
PORT_BASE=40000
declare -a DATA_DIRECTORY=(/data/primary)
MASTER_HOSTNAME=ka
MASTER_DIRECTORY=/data/master
MASTER_PORT=5432
TRUSTED_SHELL=ssh
CHECK_POINT_SEGMENTS=8
ENCODING=UNICODE
MIRROR_PORT_BASE=50000
REPLICATION_PORT_BASE=41000
MIRROR_REPLICATION_PORT_BASE=51000
declare -a MIRROR_DATA_DIRECTORY=(/data/mirror)
```

创建数据目录

```shell
$ gpssh -f all_hosts
=> sudo mkdir /data
=> sudo chown gpadmin.gpadmin /data
=> mkdir /data/master
=> mkdir /data/primary
=> mkdir /data/mirror
```

初始化集群

```shell
$ gpinitsystem -c gpinitsystem_config -h all_segs -s kas -S
```

配置主机和备机的环境变量

```shell
$ vi .bashrc
if [ -f /home/gpadmin/gpdb/Greenplum_path.sh ]; then
	source /home/gpadmin/gpdb/Greenplum_path.sh
	export MASTER_DATA_DIRECTORY=/data/master/gpseg-1
fi
$ source .bashrc
```

# 使用Greenplum

```shell
$ psql -hgp -dpostgres
```

