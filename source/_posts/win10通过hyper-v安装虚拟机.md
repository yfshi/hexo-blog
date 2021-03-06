---
layout: _post
title: win10通过hyper-v安装虚拟机
date: 2018-04-20 13:11:55
tags:
- Hyper-V
- 虚拟机
categories: 常用工具
---

# 安装Hyper-v组件

控制面板 -> 程序和功能 -> 启用或关闭Windows功能 -> 选中Hyper-V -> 确定

![Windows功能](/img/HV-Windows功能.PNG)

开始菜单 -> Windows管理工具 -> Hyper-v管理器

# 配置Hyper-V网络

打开虚拟交换机管理器创建虚拟交换机。一般使用内部或外部。

![虚拟交换机管理器](/img/HV-虚拟交换机管理器.jpg)

* 外部

  网桥方式，相当于物理网卡。

* 内部

  nat方式，可以连接主机，可以通过主机上网。

* 专用

  虚拟机使用，不能和主机通信。

# 安装虚拟机

## 新建虚拟机向导

![向导-名称和位置](/img/HV-向导-名称和位置.jpg)

![向导-指定虚拟机为1代](/img/HV-向导-指定虚拟机为1代.jpg)

![向导-设置硬盘](/img/HV-向导-设置硬盘.jpg)

## 虚拟机设置

关闭自动检查点，没什么用处

![关闭自动检查点](/img/HV-关闭自动检查点.jpg)

添加磁盘驱动器

![设置硬盘](/img/HV-设置硬盘.jpg)

新建或使用已经存在的磁盘（可以通过拷贝其他虚拟机的磁盘到新建的虚拟机方式克隆）

![新建或附加ing盘](/img/HV-新建或附加ing盘.jpg)

## 安装系统

右键连接，启动系统安装

![连接](/img/HV-连接.jpg)

安装系统并初始化配置，之后创建检查点
