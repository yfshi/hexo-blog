---
layout: _posts
title: CentOS安装搜狗输入法
date: 2020-08-31 16:29:14
categories: 操作系统
tags:
- sogou
- 搜狗
- 输入法
---

系统版本：`CentOS Linux release 7.7.1908 (Core)`

## 安装fcitx输入法框架

安装fcitx输入法框架，注意不要删除ibus框架，gnome-shell依赖ibus框架，执行命令：

```shell
$ sudo yum install libQtWebKit* fcitx fcitx-libs fcitx-qt4 fcitx-qt5 fcitx-configtool fcitx-table fcitx-table-chinese qt5-qtbase
```

新建`/etc/profile.d/fcitx.sh`，内容如下：

```shell
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export QT4_IM_MODULE=fcitx
export XMODIFIERS="@im=fcitx"```
```

设置`fctix`开机自启动，在`gnome-tweaks`中设置;

设置当前用户默认不启动`ibus-daemon`：

```shell
$ sudo setfacl -m u:yfshi:rw /usr/bin/ibus-daemon
```

为了在`gnome-terminal`中也能使用`fcitx`，设置如下，这是gnome3的新特性导致的：

```shell
$ gsettings set org.gnome.settings-daemon.plugins.xsettings overrides "{'Gtk/IMModule':<'fcitx'>}"
```

设置a`lternatives`为`fcitx`

```shell
$ alternatives --install /etc/X11/xinit/xinputrc xinputrc /etc/X11/xinit/xinput.d/fcitx.conf 100
$ alternatives --config xinputrc
```

## 安装搜狗输入法

下载搜狗输入法for linux，只有deb包：

```shell
$ sudo wget http://cdn2.ime.sogou.com/dl/index/1524572264/sogoupinyin_2.2.0.0108_amd64.deb?st=EPtVkvlW9rLVsn-jtfOGbA&e=1568569239&fn=sogoupinyin_2.2.0.0108_amd64.deb
```

安装`alien`工具，把deb转成rpm包：

```shell
$ sudo yum install alien
$ sudo alien -r --scripts sogoupinyin_2.2.0.0108_amd64.deb
```

安装搜狗拼音输入法：

```shell
$ sudo cp /usr/lib/x86_64-linux-gnu/fcitx/* /usr/lib64/fcitx
$ chmod -R 755 /usr/lib64/fcitx/
```

## 配置搜狗输入法

重启`reboot`；

`fcitx`添加搜狗输入法：

```shell
$ fcitx-configtool
```

> 注意，在fcitx-configtool的高级设置中关闭搜狗输入法的云输入，否则cpu可能会100%.

设置搜狗输入法。