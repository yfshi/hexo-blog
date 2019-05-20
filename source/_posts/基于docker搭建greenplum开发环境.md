---
layout: _post
title: docker搭建greenplum开发环境
date: 2019-05-15 10:00:40
tags:
- docker
- greenplum
- centos
categories: PostgreSQL
---

# docker

# 安装docker

略

# 给普通用户权限

```shell
# 把普通用户加入docker组，如果docker用户组不存在，新建
sudo gppasswd -a yfshi docker
# 重启docker服务
sudo systemctl restart docker
```

# 配置greenplum环境

```shell
# 创建自定义网络，以便后续设置静态ip
$ docker network create --subnet 10.0.0.0/24 syf_net

# 拉取centos7最小安装镜像
$ docker pull centos

#  创建并后台启动容器，名称为dev，使用自定义的网络syf_net，指定静态ip（比如属于syf_net所指定的子网，如果使用非自定义网络，不可设置静态ip，自动分配）
$ docker run -dit --privileged --net syf_net --ip 10.0.0.1 -dit --name dev centos /usr/sbin/init

# 在容器中打开一个交互终端
$ docker exec -it dev /bin/bash

# 安装常用工具和开发包
$ yum install -y net-tools which openssh-clients openssh-server less zip unzip iproute bzip2 cmake gcc gcc-c++ gdb git libtool lrzsz make man net-tools sysstat vim wget sudo
$ yum install -y apr-devel apr-util-devel bison bzip2-devel c-ares-devel flex java-1.8.0-openjdk java-1.8.0-openjdk-devel json-c-devel krb5-devel libcurl-devel libevent-devel libkadm5 libxml2-devel libxslt-devel libyaml-devel openldap-devel openssl-devel pam-devel perl perl-devel perl-ExtUtils-Embed readline-devel unixODBC-devel zlib-devel

# 设置系统参数
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

# 设置ssh自启动
systemctl enable sshd
systemctl start sshd

# 添加用户
passwd root
useradd -m gpadmin
passwd gpadmin

# 退出当前终端
exit

# 把该容器制作为镜像
docker commit -a yfshi -m "develop environment for greenplum" dev centos-gpdb

#  基于新镜像启动容器
docker run -dit --privileged --net syf_net --ip 10.0.0.2 -dit --name dev1 centos-gpdb /usr/sbin/init

# 打开终端，可以以ssh方式或docker方式
docker exec -it dev1 /bin/bash
# 或
ssh gpadmin@10.0.0.2
```

# 备份镜像

为了防止镜像丢失，可以把镜像导出到文件。之后可以通过该文件导入镜像。

有两种方式，一种是通过save/load镜像方式，一种是通过export/import容器方式。区别是export/import不保留历史记录（docker history IMAGE）。

```shell
# 把centos-gpdb镜像导出到文件centos-gpdb.tar
docker save -o centos-gpdb.tar centos-gpdb

# 导入centos-gpdb.tar
docker load -i centos-gpdb.tar
```









附：docker建立ubuntu桌面版，通过vnc连接

```shell
# 启动容器
$ docker run -d --name=ubuntu -p 5901:5901 -p 6901:6901 --hostname ubuntu --user $(id -u) --net sys_net --ip 10.0.0.200 -e VNC_PW=yfshi -e VNC_RESOLUTION=1280x800  consol/ubuntu-xfce-vnc

# 使用浏览器访问: x.x.x.x:6901
# 使用vnc客户端访问：x.x.x.x:5901
```

