---
title: 'centos/redhat搭建本地yum源'
date: 2017-09-25
tags: yum
---

# 创建仓库

1. 把所有的光盘或iso文件（ios可能有两个或多个）中的rpm包拷贝出来
2. 使用createrepo创建仓库

```bash
$ mkdir -p /opt/yum/centos6.7/Packages
$ mount /dev/cdrom /mnt
$ createrepo -v -g /mnt/repodata/*-comps.xml /opt/yum/centos6.7
```

createrepo的-g的作用是加载分组信息`yum grouplist`，可以用下面两条命令实现通用的功能：

```bash
$ createrepo -v /opt/yum/centos6.7
# cp /mnt/repodata/*-comps.xml* /opt/yum/centos6.7/repodata/
```

# 设置repo文件

新建repo文件`touch /etc/yum.repo/local.repo`，或者直接在原有的repo文件中添加，内容如下：

```bash
[local_server]
name=This is a local repo
baseurl=file:///home/yum/centos6.7
enabled=1
gpgcheck=0
```

可以把原来的Centos-Base.repo中的源都加上`enable=0`禁用，否则会先去找这个文件中的路径

# 常用命令

```bash
yum clean all
yum list
yum install xxx.rpm
yum install -y xxx.rpm
yum uninstall xxx
yum grouplist
yum groupinstall xxx
yum groupinstall -y xxx
yum ungroup xxx
yum makecache
```