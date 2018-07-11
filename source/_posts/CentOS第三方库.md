---
layout: _post
title: CentOS第三方库
date: 2018-07-11 11:36:00
tags: linux
---

`Software Collections`

`EPEL` `Remi` `CentOS`

在Red Hat企业Linux（RHEL）上，一般都是提供的老掉牙的软件。CentOS作为RHEL的复制品有着同样的问题。

如果应用依赖新版软件，怎么办呢？使用第三方仓库，推荐Software Collections、epel、Remi Collet。

* Software Collections

  单独安装在/opt中，新旧软件分离，需要启动。

* epel

  新旧软件不分离，容易造成混乱。无需启动，直接生效。

* Remi Collet

  同epel。

# Software Collections

[Software Collections](https://www.softwarecollections.org/en/)是 Red Hat 唯一支持的新软件包源，为 CentOS 设立了专门的仓库，安装和管理都和其它第三方仓库一样。

在 CentOS 6/7上安装Software Collections命令如下：

```shell
$ sudo yum install centos-release-scl
```

`centos-release-scl-rh` 可能作为依赖包被同时安装。

然后就可以像平常一样搜索、安装软件包了：

```shell
$ yum search php7
 [...]
 rh-php70.x86_64 : Package that installs PHP 7.0
 [...]
$ sudo yum install rh-php70 
```

启用：

```shell
$ scl enable rh-php70 bash
$ php -v
PHP 7.0.10
```

这些 SCL 软件包在重启后不会激活。SCL 的设计初衷就是在不影响原有配置的前提下，让新旧软件能一起运行。不过你可以通过 `~/.bashrc` 加载 SCL 提供的 `enable` 脚本来实现自动启用。 SCL 的所有软件包都安装在 `/opt` 下， 以我们的 PHP 7 为例，在 `~/.bashrc` 里加入一行：

```shell
source /opt/rh/rh-php70/enable
```

# EPEL

Fedora 社区为 Feora 及所有 RHEL 系的发行版维护着 [EPEL：Extra Packages for Enterprise Linux](https://fedoraproject.org/wiki/EPEL) 。 里面包含一些最新软件包以及一些未被发行版收纳的软件包。

CentOS6/7安装命令如下：

```shell
yum install -y epel-release
```

安装 EPEL 里的软件就不用麻烦 `enable` 脚本了，直接像平常一样用。你还可以用 `--disablerepo` 和 `--enablerepo` 选项指定从 EPEL 里安装软件包：

```shell
$ sudo yum --disablerepo "*" --enablerepo epel install [package]
```

# Remi Collet

Remi Collet 在 [Remi 的 RPM 仓库](http://rpms.remirepo.net/) 里维护着大量更新的和额外的软件包。需要先安装 EPEL ，因为 Remi 仓库依赖它。

CentOS wiki 上有较完整的仓库列表：[更多的第三方仓库](https://wiki.centos.org/AdditionalResources/Repositories) ，用哪些，不用哪些，里面都有建议。

# 指定仓库

列出可用仓库：

```shell
$ yum repolist
[...]
repo id                  repo name
base/7/x86_64            CentOS-7 - Base
centos-sclo-rh/x86_64    CentOS-7 - SCLo rh
centos-sclo-sclo/x86_64  CentOS-7 - SCLo sclo
extras/7/x86_64          CentOS-7 - Extras
updates/7/x86_64         CentOS-7 - Updates
```

列出指定仓库中的 软件包：

```shell
$ yum --disablerepo "*" --enablerepo centos-sclo-rh list available
```

`--disablerepo` 与 `--enablerepo` 简单说下。 实际上在这个命令里你并没有禁用或启用什么东西，而只是将你的搜索范围限制在某一个仓库内。

从指定仓库安装：

```shell
$ sudo yum --disablerepo "*" --enablerepo epel install [package]
```