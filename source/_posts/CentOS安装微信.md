---
layout: _post
title: CentOS安装微信
date: 2020-09-01 10:23:44
categories: 操作系统
tags:
微信
wechat
---

# CentOS安装微信

系统版本：`CentOS Linux release 7.7.1908 (Core)`

## 安装docker

### 配置docker的yum源

```shell
$ sudo yum-config-manager  --add-repo https://download.docker.com/linux/centos/docker-ce.repo
$ sudo yum-config-manager --enable docker-ce-nightly
$ sudo yum-config-manager --enable docker-ce-test
$ sudo yum-config-manager --disable docker-ce-nightly
```

### 安装docker-ce

```shell
$ sudo yum install docker-ce
```

### 启动docker

```shell
$ sudo systemctl start docker
$ sudo systemctl enable docker
```

## 安装微信

### 拉取docker微信镜像

bestwu/wechat是基于deepin的镜像，内部包含基于deepin-wine的微信。

```shell
$ sudo docker pull bestwu/wechat
```

### 创建微信容器

```shell
$ sudo docker run -d --name wechat --device /dev/snd \
		   -v /tmp/.X11-unix:/tmp/.X11-unix \
		   -v $HOME/.WeChatFiles:/WeChatFiles \
		   -e DISPLAY=unix$DISPLAY \
		   -e XMODIFIERS=@im=ibus \
		   -e QT_IM_MODULE=ibus \
		   -e GTK_IM_MODULE=ibus \
		   -e AUDIO_GID=`getent group audio | cut -d: -f3` \
		   -e GID=`id -g` \
		   -e UID=`id -u` \
		   bestwu/wechat
```

> 上述是基于fcitx的输入法框架，如果是ibus，把上述fcitx都换成ibus即可。

### 启动微信容器

第一次使用`docker run`创建并启动微信容器，以后每次使用`docker start`启动微信容器。

```shell
$ sudo docker start wechat
```