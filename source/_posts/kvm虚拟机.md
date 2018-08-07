---
layout: _post
title: kvm虚拟机
date: 2018-02-09 00:22:51
tags:
- kvm
- 虚拟机
categories: 常用工具
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

2. 建立`xml`配置文件

   `linux`默认有`virtio`驱动，磁盘总线、网卡等可以设置为`virtio`。

   `windows`要使用`virtio`，需要安装`virtio`驱动。或者`windows`的`disk`的总线可以选择和宿主机一致比如是`sata`，网卡可以设置为`rt8139`，`<hyperv>...</hyperv>`域是针对`windows`的优化。实际上使用时发现在机械硬盘是使用`windows`，`io`效率很低，无论是否使用`virtio`驱动，可能有什么地方需要优化没搞懂，后来把`windows`的存储放到`ssd`上了。

   **centos7.0.xml**

   ```xml
   <domain type='kvm'>
     <name>centos7.0</name>
     <memory unit='KiB'>1048576</memory>
     <currentMemory unit='KiB'>1048576</currentMemory>
     <vcpu placement='static'>2</vcpu>
     <os>
       <type arch='x86_64'>hvm</type>
       <boot dev='cdrom'/>
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
         <driver name='qemu' type='qcow2' cache='writeback'/>
         <source file='/vmhosts/kvm/centos7.0.qcow2'/>
         <target dev='vda' bus='virtio'/>
       </disk>
       <disk type='file' device='cdrom'>
         <driver name='qemu' type='raw' cache='none'/>
         <source file='/iso/centos7.0.iso'/>
         <target dev='hda' bus='ide'/>
         <readonly/>
       </disk>
       <interface type='bridge'>
         <source bridge='br0'/>
         <model type='virtio'/>
       </interface>
       <input type='tablet' bus='usb'/>
       <input type='mouse' bus='ps2'/>
       <input type='keyboard' bus='ps2'/>
       <graphics type='vnc' port='-1' autoport='yes' listen='0.0.0.0'>
         <listen type='address' address='0.0.0.0'/>
       </graphics>
     </devices>
   </domain>
   ```
   **win7**

   ```shell
   <domain type='kvm'>
     <name>win7</name>
     <memory unit='KiB'>2097152</memory>
     <currentMemory unit='KiB'>2097152</currentMemory>
     <vcpu placement='static'>2</vcpu>
     <os>
       <type arch='x86_64'>hvm</type>
       <boot dev='cdrom'/>
       <boot dev='hd'/>
     </os>
     <features>
       <acpi/>
       <apic/>
       <hyperv>
         <relaxed state='on'/>
         <vapic state='on'/>
         <spinlocks state='on' retries='4096'/>
         <vpindex state='on'/>
         <runtime state='on'/>
         <synic state='on'/>
         <reset state='on'/>
       </hyperv>
       <vmport state='off'/>
     </features>
     <cpu mode='host-model' check='partial'>
       <model fallback='allow'/>
     </cpu>
     <clock offset='localtime'>
       <timer name='rtc' tickpolicy='catchup'/>
       <timer name='pit' tickpolicy='delay'/>
       <timer name='hpet' present='no'/>
       <timer name='hypervclock' present='yes'/>
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
         <driver name='qemu' type='qcow2' cache='writeback'/>
         <source file='/vmhosts/kvm/centos7.0.qcow2'/>
         <target dev='sda' bus='sata'/>
       </disk>
       <disk type='file' device='cdrom'>
         <driver name='qemu' type='raw' cache='none'/>
         <source file='/iso/win7.iso'/>
         <target dev='hda' bus='ide'/>
         <readonly/>
       </disk>
       <interface type='bridge'>
         <source bridge='br0'/>
         <model type='rt8139'/>
       </interface>
       <input type='tablet' bus='usb'/>
       <input type='mouse' bus='ps2'/>
       <input type='keyboard' bus='ps2'/>
       <graphics type='vnc' port='-1' autoport='yes' listen='0.0.0.0'>
         <listen type='address' address='0.0.0.0'/>
       </graphics>
     </devices>
   </domain>
   ```

   ​

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
   安装好系统，装完必要的环境之后可以把存储(centos7.0.qcow2)备份。之后再需要系统时直接拷贝过来使用即可。

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

# 快照管理

```shell
# virsh --help | grep snapshot
snapshot-create                Create a snapshot from XML
snapshot-create-as             Create a snapshot from a set of args
snapshot-current               Get or set the current snapshot
snapshot-delete                Delete a domain snapshot
snapshot-dumpxml               Dump XML for a domain snapshot
snapshot-edit                  edit XML for a snapshot
snapshot-info                  snapshot information
snapshot-list                  List snapshots for a domain
snapshot-parent                Get the name of the parent of a snapshot
snapshot-revert                Revert a domain to a snapshot
```

举例：

```shell
# virsh list
 Id    Name                           State
----------------------------------------------------
 1     win7                           running

# virsh snapshot-create-as win7 snapshot-haozip_360_npp_wps
Domain snapshot snapshot-haozip_360_npp_wps created

# qemu-img info win7.qcow2
image: win7.qcow2
file format: qcow2
virtual size: 100G (107374182400 bytes)
disk size: 14G
cluster_size: 65536
Snapshot list:
ID        TAG                 VM SIZE                DATE       VM CLOCK
1         snapshot-haozip_360_npp_wps   1.8G 2018-03-07 10:14:03   01:15:31.438
Format specific information:
    compat: 1.1
    lazy refcounts: false
    refcount bits: 16
    corrupt: false

# virsh snapshot-list win7
 Name                 Creation Time             State
------------------------------------------------------------
 snapshot-haozip_360_npp_wps 2018-03-07 10:14:03 +0800 running

# virsh snapshot-info win7 --snapshotname snapshot-haozip_360_npp_wps
Name:           snapshot-haozip_360_npp_wps
Domain:         win7
Current:        yes
State:          running
Location:       internal
Parent:         -
Children:       0
Descendants:    0
Metadata:       yes
```

# 虚拟磁盘扩容

磁盘扩容或添加之后要到虚拟机内部做分区、格式化、自动挂在等操作。

1. 磁盘扩容

   ```shell
   # qemu-img resize win7.qcow +10G
   ```

2. 磁盘添加

   ```shell
   # qemu-img create -f qcow2 win7_1 10G
   # virsh shutdown win7
   # virsh edit win7
   <disk></disk>在原有的disk下面添加一个disk配置：
   -- 修改file路径
   -- target中的dev修改为vdb
   -- 删除address
   ```

# 图形界面

通过执行名virt-manager，启动libvirt的图形界面，在图形界面下可以一步一步的创建虚拟机，管理虚拟机，还可以直接控制虚拟机的桌面。​
