---
layout: _post
title: CentOS编译安装wine
date: 2020-09-03 17:38:58
categories: 操作系统
tags:
- wine
---

## CentOS编译安装wine

## 安装依赖

```shell
$ yum install glibc-devel.i686 dbus-devel.i686 freetype-devel.i686 pulseaudio-libs-devel.i686 libX11-devel.i686 mesa-libGLU-devel.i686 libICE-devel.i686 libXext-devel.i686 libXcursor-devel.i686 libXi-devel.i686 libXxf86vm-devel.i686 libXrender-devel.i686 libXinerama-devel.i686 libXcomposite-devel.i686 libXrandr-devel.i686 mesa-libGL-devel.i686 mesa-libOSMesa-devel.i686 libxml2-devel.i686 libxslt-devel.i686 zlib-devel.i686 gnutls-devel.i686 ncurses-devel.i686 sane-backends-devel.i686 libv4l-devel.i686 libgphoto2-devel.i686 libexif-devel.i686 lcms2-devel.i686 gettext-devel.i686 isdn4k-utils-devel.i686 cups-devel.i686 fontconfig-devel.i686 gsm-devel.i686 libjpeg-turbo-devel.i686 pkgconfig.i686 libtiff-devel.i686 unixODBC.i686 openldap-devel.i686 alsa-lib-devel.i686 audiofile-devel.i686 freeglut-devel.i686 giflib-devel.i686 gstreamer-devel.i686 gstreamer-plugins-base-devel.i686 libXmu-devel.i686 libXxf86dga-devel.i686 libieee1284-devel.i686 libpng-devel.i686 librsvg2-devel.i686 libstdc++-devel.i686 libusb-devel.i686 unixODBC-devel.i686 qt-devel.i686 libXext.i686 xulrunner.i686 ia32-libs.i686
```

##　编译安装wine

> wine版本下载最新的稳定版，目前是wine 5.0.2版本。

```shell
$ wget http://mirrors.ibiblio.org/wine/source/5.0/wine-5.0.2.tar.xz
$ tar xf wine-5.0.2.tar.xz
$ cd wine-5.0.2
$ ./configure --prefix=/usr/local # 如果编译64位增加--enable-wine64
$ make -j8
$ sudo make install
```

## 初始化wine

> `wine-mono`和`wine-geoko`可以初始化时安装，也可以不安装，下载后通过`wine control`命令安装exe或msi。

```shell
$ wineboot
$ cp -f /usr/local/share/wine/fonts/* .wine/drive_c/windows/Fonts/
```

