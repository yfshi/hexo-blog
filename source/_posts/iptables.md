---
layout: _post
title: iptables
date: 2018-09-14 16:35:52
categories: 操作系统
tags:
- iptables
- netfilter
- snat
- dnat
- 防火墙
---

# netfilter/iptables

netfilter是linux内核2.4.x引入的一个子系统，作为一个通用的、抽象的框架，提供一整套的hook（钩子、检查点）函数的管理机制，使得诸如包过滤、网络地址转换(NAT)和基于协议类型的连接跟踪成为了可能。

netfilter的架构就是在整个网络流程的若干位置放置了一些检测点（hook），而在每个检测点上登记了一些处理函数进行处理。

![](/img/iptables/netfilter-hook.jpg)

netfilter主要采用连线跟踪（Connection Tracking）、包过滤（Packet Filtering）、地址转换（NAT）、包处理（Packet Mangling)4种关键技术。

* 连线跟踪

  是包过滤、地址转换的基础，它作为一个独立的模块运行。采用连线跟踪技术在协议栈低层截取数据包，将当前数据包及其状态信息与历史数据包及其状态信息进行比较，从而得到当前数据包的控制信息，根据这些信息决定对网络数据包的操作，达到保护网络的目的。

  当下层网络接收到初始化连接同步（Synchronize，SYN）包，将被netfilter规则库检查。该数据包将在规则链中依次序进行比较。如果该包应被丢弃，发送一个复位（Reset，RST）包到远端主机，否则连接接收。这次连接的信息将被保存在连线跟踪信息表中，并表明该数据包所应有的状态。这个连线跟踪信息表位于内核模式下，其后的网络包就将与此连线跟踪信息表中的内容进行比较，根据信息表中的信息来决定该数据包的操作。因为数据包首先是与连线跟踪信息表进行比较，只有SYN包才与规则库进行比较，数据包与连线跟踪信息表的比较都是在内核模式下进行的，所以速度很快。

* 包过滤

  包过滤检查通过的每个数据包的头部，然后决定如何处置它们，可以选择丢弃，让包通过，或者更复杂的操作。

* 地址转换

  网络地址转换分为源NAT（Source NAT，SNAT）和目的NAT（Destination NAT,DNAT）2种不同的类型。SNAT是指修改数据包的源地址（改变连接的源IP）。SNAT会在数据包送出之前的最后一刻做好转换工作。地址伪装（Masquerading）是SNAT的一种特殊形式。DNAT 是指修改数据包的目标地址（改变连接的目的IP）。DNAT 总是在数据包进入以后立即完成转换。端口转发、负载均衡和透明代理都属于DNAT。

* 包处理

  利用包处理可以设置或改变数据包的服务类型（Type of Service,TOS）字段；改变包的生存期（Time to Live,TTL）字段；在包中设置标志值，利用该标志值可以进行带宽限制和分类查询。

iptables是运行在用户空间的一个防火墙管理工具，真正的防火墙是netfilter。

netfilter组件是内核模块，iptables是用户空间工具。

![](/img/iptables/system-netfilter-iptables.jpg)

# 四表五链

* 规则（rule）

* 规则表（table）

  实现特定功能的规则的集合。iptables内置了4个表，raw、mangle、nat、filter表，分表用于实现数据跟踪处理、包重构、网络地址转换和包过滤。

* 规则链（chain）

  一个chain就是一个检查清单（钩子、hook），每一条链中可以有多个规则。一共预定义了五个规则链。

* 自定义链

  用户可以自定义链。但是无法自动触发，需要由预定义链跳转过来。

![](/img/iptables/table-chain.jpg)

# 网络数据流向

![](/img/iptables/网络数据流向.jpg)

有三条报文类型：

* 进入本机的报文

  网络 -> PREROUTING -> route -> INPUT -> 本机应用

* 本机发出的报文

  本机应用 -> route -> OUTPUT -> POSTROUTING

* 转发的报文

  网路A -> PREROUTING -> route -> FORWARD -> POSTROUTING -> 网络B

# iptables用法

可以根据下面两图使用iptables

![](/img/iptables/iptables-cmd.gif)

![](/img/iptables/iptables-cmd1.jpg)

# 例子

## nat

局域网通过snat网关上网；局域网的web服务器需要映射到外网；

![](/img/iptables/snat.jpg)

![](/img/iptables/dnat.jpg)

```shell
# 首先打开路由转发功能
$ sysctl -w net.ipv4.ip_forward=1 
# 永久生效方法 echo "net.ipv4.ip_forward=1">>/etc/sysctl.conf && sysctl -p

# snat访问外网
$ iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# dnat映射内网服务器
$ iptables -t nat -p tcp --dport 80 -A PREROUTING -i eth1 -j DNAT --to-destination 192.168.1.6

# 保存
$ service iptables save
```

## filter

限制本机的web服务器在周一不允许访问； 新请求的速率不能超过100个每秒；web服务器包含了admin字符串的页面不允许访问；web 服务器仅允许响应报文离开本机；

```shell
# 周一不允许访问
$ iptables -A INPUT -p tcp --dport 80 -m time ! --weekdays Mon -j ACCEPT
$ iptables -A OUTPUT -p tcp --dport 80 -m state --state ESTABLISHED -j ACCEPT

# 新请求速率不能超过100个每秒
$ iptables -A INPUT -p tcp --dport 80 -m limit --limit 100/s -j ACCEPT

# web包含admin字符串的页面不允许访问，源端口：dport
$ iptables -A INPUT -p tcp --dport 80 -m string --algo bm --string 'admin' -j REJECT

# web服务器仅允许响应报文离开主机,目标端口：sport
$ iptables -A OUTPUT -p tcp --sport 80 -m state --state ESTABLISHED -j ACCEPT
```

在工作时间，即周一到周五的8:30-18:00，开放本机的ftp服务给192.168.1.0网络中的主机访问；数据下载请求的次数每分钟不得超过 5 个；

```shell
$ iptables -A INPUT -p tcp --dport 21 -s 192.168.1.0/24 -m time ! --weekdays 6,7 -m time --timestart 8:30 --timestop 18:00 -m connlimit --connlimit-above 5 -j ACCET
```

开放本机的ssh服务给192.168.1.1-192.168.1.100 中的主机；新请求建立的速率一分钟不得超过2个；仅允许响应报文通过其服务端口离开本机；

```shell
$ iptables -A INPUT -p tcp --dport 22 -m iprange --src-rang 192.168.1.1-192.168.1.100 -m limit --limit 2/m -j ACCEPT
$ iptables -A OUTPUT -p tcp --sport 22 -m iprange --dst-rang 192.168.1.1-192.168.1.100 -m state --state ESTABLISHED -j ACCEPT
```

拒绝 TCP 标志位全部为 1 及全部为 0 的报文访问本机；

```shell
$ iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
```

允许本机 ping 别的主机；但不开放别的主机 ping 本机；

```shell
$ iptables -I INPUT -p icmp --icmp-type echo-request -j DROP 
$ iptables -I INPUT -p icmp --icmp-type echo-reply -j ACCEPT 
$ iptables -I INPUT -p icmp --icmp-type destination-Unreachable -j ACCEPT
# 或者下面禁ping操作：
$ echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_all
```

##　其他

```shell
# 开通本机的22端口，允许192.168.1.0网段的服务器访问
$ iptables -A INPUT -s 192.168.1.0/24 -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT

# 开通本机的80端口，只允许192.168.1.150机器访问
$ iptables -t filter -A INPUT -s 192.168.1.150/32 -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT

# 拒绝进入防火墙的所有ICMP协议数据包
$ iptables -I INPUT -p icmp -j REJECT

# 允许防火墙转发除ICMP协议以外的所有数据包
$ iptables -A FORWARD -p ! icmp -j ACCEPT

# 拒绝转发来自192.168.1.10主机的数据，允许转发来自192.168.0.0/24网段的数据
$ iptables -A FORWARD -s 192.168.1.11 -j REJECT 
$ iptables -A FORWARD -s 192.168.0.0/24 -j ACCEPT
# 注意一定要把拒绝的放在前面不然就不起作用了！

# 丢弃从外网接口（eth1）进入防火墙本机的源地址为私网地址的数据包
$ iptables -A INPUT -i eth1 -s 192.168.0.0/16 -j DROP 
$ iptables -A INPUT -i eth1 -s 172.16.0.0/12 -j DROP 
$ iptables -A INPUT -i eth1 -s 10.0.0.0/8 -j DROP

# 只允许管理员从202.13.0.0/16网段使用SSH远程登录防火墙主机
$ iptables -A INPUT -s 202.13.0.0/16 -p tcp -m tcp -m state --state NEW --dport 22  -j ACCEPT 

# 允许本机开放从TCP端口20-1024提供的应用服务
$ ptables -A INPUT -p tcp -m tcp -m state --state NEW --dport 20:1024 -j ACCEPT

# 允许转发来自192.168.0.0/24局域网段的DNS解析请求数据包
$ iptables -A FORWARD -s 192.168.0.0/24 -p udp --dport 53 -j ACCEPT 
$ iptables -A FORWARD -d 192.168.0.0/24 -p udp --sport 53 -j ACCEPT

# 屏蔽环回(loopback)访问
$ iptables -A INPUT -i lo -j DROP
$ iptables -A OUTPUT -o lo -j DROP

# 屏蔽来自外部的ping，即禁止外部机器ping本机
$ iptables -A INPUT -p icmp --icmp-type echo-request -j DROP
$ iptables -A OUTPUT -p icmp --icmp-type echo-reply -j DROP

# 屏蔽从本机ping外部主机，禁止本机ping外部机器
$ iptables -A OUTPUT -p icmp --icmp-type echo-request -j DROP
$ iptables -A INPUT -p icmp --icmp-type echo-reply -j DROP

# 禁止其他主机ping本机，但是允许本机ping其他主机（禁止别人ping本机，也可以使用echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_all）
$ iptables -I INPUT -p icmp --icmp-type echo-request -j DROP 
$ iptables -I INPUT -p icmp --icmp-type echo-reply -j ACCEPT 
$ iptables -I INPUT -p icmp --icmp-type destination-Unreachable -j ACCEPT

# 禁止转发来自MAC地址为00：0C：29：27：55：3F的和主机的数据包
$ iptables -A FORWARD -m mac --mac-source 00:0c:29:27:55:3F -j DROP
# iptables中使用“-m 模块关键字”的形式调用显示匹配。咱们这里用“-m mac –mac-source”来表示数据包的源MAC地址

# 允许防火墙本机对外开放TCP端口20、21、25、110以及被动模式FTP端口1250-1280
$ iptables -A INPUT -p tcp -m multiport --dport 20,21,25,110,1250:1280 -j ACCEPT
$ iptables -A INPUT -p tcp -m tcp -m multiport --dports 22,80,443,1250-1280 -m state --state NEW -j ACCEPT
# 也可以将这几个端口分开设置多行：
$ iptables -A INPUT -p tcp -m tcp -m state --state NEW --dport 22 -j ACCEPT
$ iptables -A INPUT -p tcp -m tcp -m state --state NEW --dport 80 -j ACCEPT
$ iptables -A INPUT -p tcp -m tcp -m state --state NEW --dport 443 -j ACCEPT
$ iptables -A INPUT -p tcp -m tcp -m state --state NEW --dport 1250:1280 -j ACCEPT

#禁止转发源IP地址为192.168.1.20-192.168.1.99的TCP数据包
$ iptables -A FORWARD -p tcp -m iprange --src-range 192.168.1.20-192.168.1.99 -j DROP

# 禁止转发与正常TCP连接无关的非--syn请求数据包
$ iptables -A FORWARD -m state --state NEW -p tcp ! --syn -j DROP
# “-m state”表示数据包的连接状态，“NEW”表示与任何连接无关的

# 拒绝访问防火墙的新数据包，但允许响应连接或与已有连接相关的数据包
$ iptables -A INPUT -p tcp -m state --state NEW -j DROP 
$ iptables -A INPUT -p tcp -m state --state ESTABLISHED,RELATED -j ACCEPT
# “ESTABLISHED”表示已经响应请求或者已经建立连接的数据包，“RELATED”表示与已建立的连接有相关性的，比如FTP数据连接等

# 防止DoS攻击
$ iptables -A INPUT -p tcp --dport 80 -m limit --limit 25/minute --limit-burst 100 -j ACCEPT
# -m limit: 启用limit扩展，限制速度。
# --limit 25/minute: 允许最多每分钟25个连接
# --limit-burst 100: 当达到100个连接后，才启用上述25/minute限制
# --icmp-type 8 表示 Echo request——回显请求（Ping请求）。下面表示本机ping主机192.168.1.109时候的限速设置：
$ iptables -I INPUT -d 192.168.1.109 -p icmp --icmp-type 8 -m limit --limit 3/minute --limit-burst 5 -j ACCEPT

# 如果本地主机有两块网卡，一块连接内网(eth0)，一块连接外网(eth1)，那么可以使用下面的规则将eth0的数据路由到eht1：
$ iptables -A FORWARD -i eth0 -o eth1 -j ACCEPT

# 拒绝进入防火墙的所有ICMP协议数据包
$ iptables -I INPUT -p icmp -j REJECT

# 允许防火墙转发除ICMP协议以外的所有数据包
$ iptables -A FORWARD -p ! icmp -j ACCEPT

# 拒绝转发来自192.168.1.10主机的数据，允许转发来自192.168.0.0/24网段的数据
$ iptables -A FORWARD -s 192.168.1.11 -j REJECT 
$ iptables -A FORWARD -s 192.168.0.0/24 -j ACCEPT
# 注意一定要把拒绝的放在前面不然就不起作用了

# 丢弃从外网接口（eth1）进入防火墙本机的源地址为私网地址的数据包
$ iptables -A INPUT -i eth1 -s 192.168.0.0/16 -j DROP 
$ iptables -A INPUT -i eth1 -s 172.16.0.0/12 -j DROP 
$ iptables -A INPUT -i eth1 -s 10.0.0.0/8 -j DROP

# 允许转发来自192.168.0.0/24局域网段的DNS解析请求数据包
$ iptables -A FORWARD -s 192.168.0.0/24 -p udp --dport 53 -j ACCEPT 
$ iptables -A FORWARD -d 192.168.0.0/24 -p udp --sport 53 -j ACCEPT

# 假设现在本机外网网关是58.68.250.1，那么把HTTP请求转发到内部的一台服务器192.168.1.20的8888端口上，规则如下
$ iptables -t nat -A PREROUTING -p tcp -i eth0 -d 58.68.250.1 --dport 8888 -j DNAT --to 192.168.1.20:80
$ iptables -A FORWARD -p tcp -i eth0 -d 192.168.0.2 --dport 80 -j ACCEPT
$ iptables -t filter -A INPUT -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT

# 把所有10.8.0.0网段的数据包SNAT成192.168.5.3的ip然后发出去
$ iptables -t nat -A POSTROUTING -s 10.8.0.0/255.255.255.0 -o eth0 -j SNAT --to-source 192.168.5.3

# 把所有10.8.0.0网段的数据包SNAT成192.168.5.3/192.168.5.4/192.168.5.5等几个ip然后发出去
$ iptables -t nat -A POSTROUTING -s 10.8.0.0/255.255.255.0 -o eth0 -j SNAT --to-source 192.168.5.3-192.168.5.5

# 从服务器的网卡上，自动获取当前ip地址来做NAT
$ iptables -t nat -A POSTROUTING -s 10.8.0.0/255.255.255.0 -o eth0 -j MASQUERADE
```

