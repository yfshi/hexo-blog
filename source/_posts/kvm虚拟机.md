---
layout: _post
title: kvm虚拟机
date: 2018-02-09 00:22:51
tags: kvm虚拟机
---

# 安装

```shell
sudo apt-get install kvm qemu-kvm libvirt-bin bridge-utils
```

* kvm 内核模块，实现cpu虚拟化和内存管理
* libvirt-bin 管理虚拟机
* qemu-kvm 是虚拟机
* bridge-utils 管理网桥

如果只是使用命令行方式，上面的软件包已经足够。

下面是图形界面工具：

```shell
sudo apt-get install virt-manager python-spice-client-gtk
```

- virt-manager 图形界面的虚拟机管理程序，需要用到python-spice-client-gtk
- python-spice-client-gtk

# 配置网桥

1. 手动配置

```shell
brctl addbr br0
brctl addif br0 eth0
ip addr add 10.10.10.1/24 dev br0
...
```

2. 自动配置

   __ubuntu__

   ```shell
   vi /etc/network/interfaces
   auto br0
   iface br0 inet static
   	address 10.10.10.1
   	netmask 255.255.255.0
   	bridge_ports eth0
   	bridge_stp off
   	bridge_fd 0
   	bridge_maxwait 0
   ```

   __centos__

   ```shell
   vi /etc/sysconfig/network-script/ifcfg-br0
   DEVICE=br0
   TYPE=Bridge
   BOOTPROTO=static
   IPADDR=10.10.10.2
   NETMASK=255.255.255.0
   ONBOOT=yes
   NM_CONTROLLED=no
   DELAY=0

   vi /etc/sysconfig/network-script/ifcfg-eth0
   DEVICE=eth0
   HWADDR=00:15:xx:xx:xx:xx
   TYPE=Ethernet
   ONBOOT=yes
   BOOTPROTO=none
   BRIDGE=br0
   NM_CONTROLLED=no
   ```

# 使用命令行创建虚拟机

1. 建立磁盘镜像

   ```shell
   qemu-img create -f qcow2 centos7.0.img 20G
   ```

   使用 qcow2 格式的磁盘镜像的好处就是它在创建之初并不会给它分配全部大小磁盘容量，而是随着虚拟机中文件的增加而逐渐增大。因此，它对空间的使用更加有效。

2. 建立xml配置文件centos7.0.xml

   ```xml
   <domain type='kvm'>
     <name>centos7.0</name>
     <memory unit='KiB'>1048576</memory>
     <currentMemory unit='KiB'>1048576</currentMemory>
     <vcpu placement='static'>2</vcpu>
     <os>
       <type arch='x86_64'>hvm</type>
       <boot dev='hd'/>
     </os>
     <features>
       <acpi/>
       <apic/>
       <vmport state='off'/>
     </features>
     <cpu mode='host-model' check='partial'>
       <model fallback='allow'/>
     </cpu>
     <clock offset='utc'>
       <timer name='rtc' tickpolicy='catchup'/>
       <timer name='pit' tickpolicy='delay'/>
       <timer name='hpet' present='no'/>
     </clock>
     <on_poweroff>destroy</on_poweroff>
     <on_reboot>restart</on_reboot>
     <on_crash>restart</on_crash>
     <pm>
       <suspend-to-mem enabled='no'/>
       <suspend-to-disk enabled='no'/>
     </pm>
     <devices>
       <emulator>/usr/bin/kvm</emulator>
       <disk type='file' device='disk'>
         <driver name='qemu' type='qcow2' cache='none'/>
         <source file='/vmhosts/kvm/centos7.0.qcow2'/>
         <target dev='vda' bus='virtio'/>
       </disk>
       <disk type='file' device='cdrom'>
         <driver name='qemu' type='raw' cache='none'/>
         <target dev='hda' bus='ide'/>
         <readonly/>
       </disk>
       <interface type='bridge'>
         <source bridge='br0'/>
         <model type='virtio'/>
       </interface>
       <input type='mouse' bus='ps2'/>
       <input type='keyboard' bus='ps2'/>
       <graphics type='vnc' port='-1' autoport='yes' listen='0.0.0.0'>
         <listen type='address' address='0.0.0.0'/>
       </graphics>
     </devices>
   </domain>
   ```

3. 定义虚拟机

   ```shell
   virsh define centos7.0.xml
   virsh list --all
   ```

4. 启动虚拟机

   ```shell
   virsh start centos7.0
   ```

5. 安装系统

   通过vnc客户端连接

   ```shell
   vncviwer localhost:5900
   ```

6. 常用命令

   ```shell
   virsh list #显示本地活动虚拟机

   virsh list –-all #显示本地所有的虚拟机（活动的+不活动的）

   virsh define ubuntu.xml #通过配置文件定义一个虚拟机（这个虚拟机还不是活动的）

   virsh start ubuntu #启动名字为ubuntu的非活动虚拟机

   virsh create ubuntu.xml # 创建虚拟机（创建后，虚拟机立即执行，成为活动主机）

   virsh suspend ubuntu # 暂停虚拟机

   virsh resume ubuntu # 启动暂停的虚拟机

   virsh shutdown ubuntu # 正常关闭虚拟机

   virsh destroy ubuntu # 强制关闭虚拟机

   virsh dominfo ubuntu #显示虚拟机的基本信息

   virsh domname 2 # 显示id号为2的虚拟机名

   virsh domid ubuntu # 显示虚拟机id号

   virsh domuuid ubuntu # 显示虚拟机的uuid

   virsh domstate ubuntu # 显示虚拟机的当前状态

   virsh dumpxml ubuntu # 显示虚拟机的当前配置文件（可能和定义虚拟机时的配置不同，因为当虚拟机启动时，需要给虚拟机分配id号、uuid、vnc端口号等等）

   virsh setmem ubuntu 512000 #给不活动虚拟机设置内存大小

   virsh setvcpus ubuntu 4 # 给不活动虚拟机设置cpu个数

   virsh edit ubuntu # 编辑配置文件（一般是在刚定义完虚拟机之后）

   libvirt还提供了一个shell:virsh，直接执行名virsh即可获得一个特殊的shell:virsh，在这个virsh里面可以执行上面的命令与本地libvirt交互，还可以通过命令connect命令连接远程libvirt，与之交互，例如：connect xen+ssh://root@10.0.0.11。另外可以只执行一条远程libvirt命令：virsh –c xen+ssh://root@10.0.0.11 list –all
   ```

# 图形界面

通过执行名virt-manager，启动libvirt的图形界面，在图形界面下可以一步一步的创建虚拟机，管理虚拟机，还可以直接控制虚拟机的桌面。​
